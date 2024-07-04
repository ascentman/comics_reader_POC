import 'dart:async';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:giphy_picker/giphy_picker.dart';

class EmojiGifPickerScreen extends StatefulWidget {
  const EmojiGifPickerScreen({super.key});

  @override
  EmojiGifPickerScreenState createState() => EmojiGifPickerScreenState();
}

class EmojiGifPickerScreenState extends State<EmojiGifPickerScreen> {
  final messages = <String>[];
  final _textController = TextEditingController();
  final keyboardController = KeyboardVisibilityController();
  bool isEmojiVisible = false;
  bool isKeyboardVisible = false;
  late StreamSubscription<bool> keyboardSubscription;

  @override
  void initState() {
    super.initState();

    keyboardSubscription =
        keyboardController.onChange.listen((bool isKeyboardVisible) {
      if (!mounted) return;
      setState(() {
        this.isKeyboardVisible = isKeyboardVisible;
      });

      if (isKeyboardVisible && isEmojiVisible) {
        if (!mounted) return;
        setState(() {
          isEmojiVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    keyboardSubscription.cancel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Emoji & Gif'),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                reverse: true,
                physics: const BouncingScrollPhysics(),
                children: messages
                    .map((message) => MessageWidget(message: message))
                    .toList(),
              ),
            ),
            InputWidget(
              onBlurred: toggleEmojiKeyboard,
              controller: _textController,
              isEmojiVisible: isEmojiVisible,
              isKeyboardVisible: isKeyboardVisible,
              onSentMessage: (message) =>
                  setState(() => messages.insert(0, message)),
            ),
            Offstage(
              offstage: !isEmojiVisible,
              child: EmojiGifPicker(
                onEmojiSelected: onEmojiSelected,
              ),
            ),
          ],
        ),
      );

  void onEmojiSelected(String emoji) => setState(() {
        _textController.text = _textController.text + emoji;
      });

  Future toggleEmojiKeyboard() async {
    if (isKeyboardVisible) {
      FocusScope.of(context).unfocus();
    }

    setState(() {
      isEmojiVisible = !isEmojiVisible;
    });
  }
}

class InputWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isEmojiVisible;
  final bool isKeyboardVisible;
  final Function onBlurred;
  final ValueChanged<String> onSentMessage;
  final focusNode = FocusNode();

  InputWidget({
    required this.controller,
    required this.isEmojiVisible,
    required this.isKeyboardVisible,
    required this.onSentMessage,
    required this.onBlurred,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Container(
        height: 50,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(width: 0.5)),
          color: Colors.white,
        ),
        child: Row(
          children: <Widget>[
            buildEmoji(),
            Expanded(child: buildTextField()),
            buildSend(),
          ],
        ),
      );

  Widget buildEmoji() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: IconButton(
          icon: Icon(
            isEmojiVisible
                ? Icons.keyboard_rounded
                : Icons.emoji_emotions_outlined,
          ),
          onPressed: onClickedEmoji,
        ),
      );

  Widget buildTextField() => TextField(
        focusNode: focusNode,
        controller: controller,
        onSubmitted: (_) => _sendAndClear(),
        style: const TextStyle(fontSize: 16),
        decoration: const InputDecoration.collapsed(
          hintText: 'Type your message...',
          hintStyle: TextStyle(color: Colors.grey),
        ),
      );

  Widget buildSend() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: IconButton(
          icon: const Icon(Icons.send),
          onPressed: () {
            if (controller.text.trim().isEmpty) {
              return;
            }
            _sendAndClear();
          },
        ),
      );

  void onClickedEmoji() async {
    if (isEmojiVisible) {
      focusNode.requestFocus();
    } else if (isKeyboardVisible) {
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
      await Future.delayed(const Duration(milliseconds: 100));
    }
    onBlurred();
  }

  void _sendAndClear() {
    onSentMessage(controller.text);
    controller.clear();
  }
}

class MessageWidget extends StatelessWidget {
  final String message;

  const MessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(12);
    const borderRadius = BorderRadius.all(radius);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: borderRadius
                .subtract(const BorderRadius.only(bottomRight: radius)),
          ),
          child: Text(
            message,
            style: const TextStyle(color: Colors.black),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class EmojiPickerWidget extends StatelessWidget {
  final ValueChanged<String> onEmojiSelected;

  const EmojiPickerWidget({
    required this.onEmojiSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: TabBarView(
        children: [
          EmojiPicker(
            onEmojiSelected: (category, emoji) => onEmojiSelected(emoji.emoji),
            config: Config(
              bottomActionBarConfig: BottomActionBarConfig(
                enabled: true,
                backgroundColor: Colors.transparent,
                buttonColor: Colors.transparent,
                buttonIconColor: Colors.black,
                customBottomActionBar: (config, state, showSearchView) {
                  return Container(
                    height: 60,
                    color: Colors.transparent,
                    child: const Column(
                      children: [
                        TabBar(
                          tabs: [
                            Tab(text: 'Emoji'),
                            Tab(text: 'Gifs'),
                          ],
                          labelColor: Colors.blue,
                          indicatorColor: Colors.blue,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const Placeholder(),
        ],
      ),
    );
  }
}

class EmojiGifPicker extends StatefulWidget {
  final ValueChanged<String> onEmojiSelected;
  const EmojiGifPicker({
    super.key,
    required this.onEmojiSelected,
  });

  @override
  EmojiGifPickerState createState() => EmojiGifPickerState();
}

class EmojiGifPickerState extends State<EmojiGifPicker> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SizedBox(
        height: 400,
        child: Scaffold(
          bottomNavigationBar: const TabBar(
            unselectedLabelColor: Colors.black,
            tabs: [
              Tab(text: 'Emoji'),
              Tab(text: 'Gifs'),
            ],
            labelColor: Colors.blue,
            indicatorColor: Colors.blue,
          ),
          body: TabBarView(
            children: [
              EmojiPicker(
                onEmojiSelected: (category, emoji) =>
                    widget.onEmojiSelected(emoji.emoji),
                config: const Config(
                  emojiSet: defaultEmojiSet,
                  categoryViewConfig: CategoryViewConfig(
                    initCategory: Category.SMILEYS,
                  ),
                  emojiViewConfig: EmojiViewConfig(
                    columns: 7,
                    emojiSizeMax: 40,
                    recentsLimit: 0,
                  ),
                  bottomActionBarConfig: BottomActionBarConfig(
                    enabled: false,
                    backgroundColor: Colors.transparent,
                    buttonColor: Colors.transparent,
                    buttonIconColor: Colors.black,
                  ),
                ),
              ),
              const Center(
                child: Text('GIF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
