import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schediel/features/image_import/domain/image_services.dart';
import 'package:schediel/features/image_import/presentation/image_crop_screen.dart';
void main() {
  testWidgets('crop coordinates and rotation are explicit before applying', (tester) async {
    CropSelection? result;
    await tester.pumpWidget(MaterialApp(home:Builder(builder:(context)=>Scaffold(body:TextButton(
      onPressed:() async { result=await Navigator.of(context).push<CropSelection>(MaterialPageRoute(builder:(_)=>const ImageCropScreen(
        image:PreparedImageFile(path:'missing-test-source.png',width:100,height:80,sourceRevision:1)))); },child:const Text('Open crop'))))));
    await tester.tap(find.text('Open crop')); await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('crop-left')),'10');
    await tester.enterText(find.byKey(const Key('crop-right')),'60');
    await tester.tap(find.byTooltip('Rotate clockwise')); await tester.pumpAndSettle();
    tester.testTextInput.hide(); await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Use region'), 200, scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
    await tester.tap(find.text('Use region')); await tester.pumpAndSettle();
    expect(result!.crop.left,10); expect(result!.crop.right,60); expect(result!.crop.bottom,80);
    expect(result!.quarterTurns,1);
  });
}
