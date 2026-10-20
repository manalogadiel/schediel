# Synthetic decoder fixtures

These files contain only generated solid colors, with no user images or metadata.
Generated locally with Pillow: solid.avif is an 8 by 6 RGB image (20, 70, 120) at quality 100;
two-pages.tiff contains two 2 by 2 RGB pages, white and black.
The AVIF fixture tests byte admission and the native-channel contract on Windows;
it does not certify an Android device codec. TIFF is decoded by the Dart image package.
