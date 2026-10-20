import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/icons.dart';
import '../../../app/format.dart';
import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/time/local_time.dart';
import '../../imports/presentation/import_review_screen.dart';
import '../application/image_import_controller.dart';
import '../application/image_import_providers.dart';
import '../domain/image_services.dart';
import 'candidate_resolution_screen.dart';
import 'image_crop_screen.dart';
import 'university_term_form.dart';

class ImageImportScreen extends ConsumerStatefulWidget {
  const ImageImportScreen({super.key});
  @override ConsumerState<ImageImportScreen> createState() => _ImageImportScreenState();
}
class _ImageImportScreenState extends ConsumerState<ImageImportScreen> {
  bool _leaving = false;
  Future<void> _close(ImageImportController c) async {
    if (_leaving) return;
    if (c.image != null || c.candidates.isNotEmpty || c.busy) {
      final discard = await showDialog<bool>(context:context,builder:(d)=>AlertDialog(
        title:const Text('Discard image draft?'),content:const Text('Nothing has been added. Unconfirmed edits and the temporary scan source will be removed.'),
        actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('Keep editing')),
          TextButton(onPressed:()=>Navigator.pop(d,true),child:const Text('Discard draft'))]));
      if (discard != true || !mounted) return;
    }
    await c.cancelDraft();
    if (!mounted) return;
    setState(()=>_leaving=true);
    WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) Navigator.of(context).pop(); });
  }
  Future<void> _review(ImageImportController c) async {
    final categories = await ref.read(categoryRepositoryProvider).loadAll();
    if (!mounted) return;
    final school = categories.where((category) => category.name.trim().toLowerCase() == 'school').firstOrNull
      ?? categories.where((category) => category.id == 'school').firstOrNull;
    final entries = c.reviewEntries(universityCategoryId: school?.id);
    if(entries==null) return;
    final result = await Navigator.of(context).push<List<String>>(MaterialPageRoute(builder:(_)=>ImportReviewScreen(
      entries:entries,sourceText:c.sourceText,sourceImagePath:c.image?.path)));
    if(result==null || !mounted) return;
    await c.cancelDraft();
    if(mounted) {
      setState(()=>_leaving=true);
      WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) Navigator.of(context).pop(); });
    }
  }
  Future<void> _crop(ImageImportController c) async {
    final image=c.image;
    if(image==null) return;
    final selection=await Navigator.of(context).push<CropSelection>(MaterialPageRoute(builder:(_)=>ImageCropScreen(image:image)));
    if(selection!=null && mounted) await c.transform(selection.crop,selection.quarterTurns);
  }
  @override Widget build(BuildContext context) {
    final c=ref.watch(imageImportControllerProvider);
    return ListenableBuilder(listenable:c,builder:(context,_)=>PopScope(canPop:_leaving,
      onPopInvokedWithResult:(didPop,_) { if(!didPop) _close(c); },child:Scaffold(
        appBar:AppBar(title:const Text('Import image'),leading:IconButton(tooltip:'Close',onPressed:()=>_close(c),icon:const AppIcon(AppIcons.close))),
        body:ListView(padding:const EdgeInsets.all(Tokens.md),children:[
          const Text('Choose a schedule image. Scan on device, then review before adding.'),
          const SizedBox(height:Tokens.md),
          Wrap(spacing:Tokens.sm,children:[
            FilledButton(onPressed:c.busy?null:()=>c.pick(ImagePickKind.gallery),child:const Text('Choose photo')),
            OutlinedButton(onPressed:c.busy?null:()=>c.pick(ImagePickKind.camera),child:const Text('Take photo')),
          ]),
          if(c.image!=null) ...[
            const SizedBox(height:Tokens.md),
            if(c.candidates.isEmpty)
              Image.file(File(c.image!.path),height:180,fit:BoxFit.contain,semanticLabel:'Exact image region to scan',
                errorBuilder:(_,_,_)=>const Text('Image preview unavailable')),
            if(c.candidates.isNotEmpty) ExpansionTile(title:const Text('Source image'),children:[
              Image.file(File(c.image!.path),height:180,fit:BoxFit.contain,semanticLabel:'Scanned image region',
                errorBuilder:(_,_,_)=>const Text('Image preview unavailable')),
            ]),
            Text('${c.image!.width} × ${c.image!.height} pixels'),
            Wrap(spacing:Tokens.sm,children:[
              TextButton(onPressed:c.busy?null:()=>_crop(c),child:const Text('Crop or rotate')),
              TextButton(onPressed:c.busy?null:c.removeSource,child:const Text('Remove source image')),
            ]),
            FilledButton(onPressed:c.busy?null:c.scan,child:const Text('Scan on device')),
          ],
          if(c.busy) ...[
            const LinearProgressIndicator(),
            Semantics(liveRegion:true,child:Text(switch(c.stage) {
              ImageImportStage.picking=>'Waiting for photo selection…',ImageImportStage.preparing=>'Preparing image…',_=>'Recognizing text on this device…'})),
            TextButton(onPressed:c.cancelWork,child:const Text('Cancel scan')),
          ],
          if(c.failure!=null) Semantics(liveRegion:true,child:Padding(padding:const EdgeInsets.symmetric(vertical:Tokens.md),child:Text(c.failure!.message))),
          if(c.notice!=null) Semantics(liveRegion:true,child:Padding(padding:const EdgeInsets.symmetric(vertical:Tokens.md),child:Text(c.notice!))),
          if(c.candidates.any((candidate) => candidate.universityTimetable))
            UniversityTermForm(key: ValueKey(c.imageDraftId), controller: c, initialZone: ref.read(deviceZoneProvider)),
          for(final candidate in c.candidates) Card(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            CheckboxListTile(value:c.selected.contains(candidate.candidateId),title:Text(c.edits[candidate.candidateId]?.title.isNotEmpty == true
                ? c.edits[candidate.candidateId]!.title : 'Unresolved title'),
              subtitle:Text([
                if(candidate.universityTimetable) _classSummary(context, c, candidate.candidateId),
                c.resolved.containsKey(candidate.candidateId)?'Ready for review':'Needs review'].join('\n')),
              onChanged:c.busy?null:(on)=>c.select(candidate.candidateId,on==true)),
            if(!candidate.universityTimetable)
              Padding(padding:const EdgeInsets.symmetric(horizontal:Tokens.md),child:SelectableText(candidate.sourceLine.text)),
            if(candidate.universityTimetable && c.edits[candidate.candidateId]!.professor.isNotEmpty)
              Padding(padding:const EdgeInsets.symmetric(horizontal:Tokens.md),child:Text(c.edits[candidate.candidateId]!.professor,
                style: Theme.of(context).textTheme.bodySmall)),
            TextButton(onPressed:c.busy?null:()=>Navigator.of(context).push<bool>(MaterialPageRoute(builder:(_)=>CandidateResolutionScreen(
              controller:c,candidate:candidate))),child:const Text('Resolve fields')),
          ])),
          if(c.candidates.isNotEmpty) FilledButton(onPressed:c.busy?null:()=>_review(c),child:const Text('Continue to review')),
          const SizedBox(height:Tokens.lg),
          const Text('Cloud AI scanning is disabled. This flow never uploads your image or OCR text.'),
        ]),
      )));
  }

  String _classSummary(BuildContext context, ImageImportController controller, String id) {
    final e = controller.edits[id]!;
    final f = Formats.of(context);
    final start = LocalTime.tryParse(e.startTime), end = LocalTime.tryParse(e.endTime);
    return [if(e.subtitle.isNotEmpty) e.subtitle,
      e.weekdays.map(f.weekdayShort).join(', '),
      if(start != null) '${f.clock(start)}${end == null ? '' : '–${f.clock(end)}'}',
      if(e.location.isNotEmpty) e.location].where((s) => s.isNotEmpty).join(' · ');
  }
}
