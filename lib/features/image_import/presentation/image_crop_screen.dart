import 'dart:io';
import 'package:flutter/material.dart';
import '../../../app/icons.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/widgets/labeled_field.dart';
import '../data/local_image_preparer.dart';
import '../domain/image_services.dart';

class CropSelection {
  const CropSelection(this.crop, this.quarterTurns);
  final PixelCrop crop;
  final int quarterTurns;
}
class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({super.key, required this.image});
  final PreparedImageFile image;
  @override State<ImageCropScreen> createState() => _ImageCropScreenState();
}
class _ImageCropScreenState extends State<ImageCropScreen> {
  late final _left=TextEditingController(text:'0'), _top=TextEditingController(text:'0'),
    _right=TextEditingController(text:'${widget.image.width}'),_bottom=TextEditingController(text:'${widget.image.height}');
  int _turns=0;
  String? _error;
  PixelCrop? get _crop {
    final l=int.tryParse(_left.text),t=int.tryParse(_top.text),r=int.tryParse(_right.text),b=int.tryParse(_bottom.text);
    if(l==null||t==null||r==null||b==null||l<0||t<0||r>widget.image.width||b>widget.image.height||r<=l||b<=t) return null;
    return PixelCrop(l,t,r,b);
  }
  @override void dispose() { for(final c in [_left,_top,_right,_bottom]) { c.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) {
    final crop=_crop;
    return Scaffold(appBar:AppBar(title:const Text('Crop or rotate'),actions:[IconButton(tooltip:'Rotate clockwise',
      onPressed:()=>setState(()=>_turns=(_turns+1)%4),icon:const AppIcon(AppIcons.rotate))]),
      body:ListView(padding:const EdgeInsets.all(Tokens.md),children:[
        const Text('Crop bounds use the original oriented image pixels. The preview shows only the selected region, then rotation.'),
        const SizedBox(height:Tokens.md),
        SizedBox(height:240,child:Center(child:crop==null?const Text('Choose a valid region'):RotatedBox(quarterTurns:_turns,
          child:AspectRatio(aspectRatio:crop.width/crop.height,child:ClipRect(child:LayoutBuilder(builder:(context,constraints)=>Stack(children:[
            Positioned(left:-crop.left*constraints.maxWidth/crop.width,top:-crop.top*constraints.maxHeight/crop.height,
              width:widget.image.width*constraints.maxWidth/crop.width,height:widget.image.height*constraints.maxHeight/crop.height,
              child:Image.file(File(widget.image.path),fit:BoxFit.fill,semanticLabel:'Selected crop region',
                errorBuilder:(_,_,_)=>const Text('Image preview unavailable'))),
          ]))))))),
        const SizedBox(height:Tokens.md),
        for(final (label,controller) in [('Left',_left),('Top',_top),('Right',_right),('Bottom',_bottom)])
          Padding(padding:const EdgeInsets.only(bottom:Tokens.sm),child:FieldLabel(label:'$label pixel',child:TextField(key:Key('crop-${label.toLowerCase()}'),controller:controller,
            keyboardType:TextInputType.number,onChanged:(_)=>setState((){})))),
        Text('Rotation: ${_turns*90}° clockwise'),
        if(_error!=null) Text(_error!),
        FilledButton(onPressed:() {
          final value=_crop;
          if(value==null) { setState(()=>_error='Choose a nonempty region inside the image bounds.'); return; }
          Navigator.of(context).pop(CropSelection(value,_turns));
        },child:const Text('Use region')),
      ]));
  }
}
