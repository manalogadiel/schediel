# R8 rules for release builds.
#
# ML Kit discovers these classes by manifest name and calls their public
# no-argument constructors through reflection. AGP 9/R8 can retain the classes
# while removing those constructors with the library's class-only consumer
# rule. That breaks component discovery before OCR can read any image.
-keep class com.google.mlkit.** implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
}
#
# google_mlkit_text_recognition references the optional Chinese, Devanagari,
# Japanese and Korean recognizers. Schediel bundles only the Latin model, so
# those classes are intentionally absent.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
