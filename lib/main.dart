import 'package:comics_reader_test_app/emoji_gif_picker.dart';
import 'package:comics_reader_test_app/image_gallery.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const PhotoViewApp());
}

class PhotoViewApp extends StatelessWidget {
  const PhotoViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: StartScreen(),
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Screen'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 30,
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ImageGallery()),
              );
            },
            child: const Text('Comics reader'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmojiGifPickerScreen(),
                ),
              );
            },
            child: const Text('Emoji and GIF Picker Demo'),
          ),
        ],
      ),
    );
  }
}
