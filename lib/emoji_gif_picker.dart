import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:giphy_picker/giphy_picker.dart';

enum MessageType { text, gif }

class Message {
  final MessageType type;
  final String content;

  Message({
    required this.type,
    required this.content,
  });
}

class EmojiGifPickerScreen extends StatefulWidget {
  const EmojiGifPickerScreen({super.key});

  @override
  EmojiGifPickerScreenState createState() => EmojiGifPickerScreenState();
}

class EmojiGifPickerScreenState extends State<EmojiGifPickerScreen> {
  final List<Message> messages = []; // Store text and GIF messages
  late Future<List<GiphyGif>> trendingGifs;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final keyboardController = KeyboardVisibilityController();
  final focusNode = FocusNode();
  bool isEmojiVisible = false;
  bool isKeyboardVisible = false;
  late StreamSubscription<bool> keyboardSubscription;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection !=
          ScrollDirection.idle) {
        focusNode.unfocus();
        setState(() {
          isEmojiVisible = false;
        });
      }
    });

    trendingGifs = _fetchTrendingGifs();
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
    _scrollController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Emoji & Gif'),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    if (message.type == MessageType.text) {
                      return MessageWidget(
                        message: message.content,
                      );
                    } else if (message.type == MessageType.gif) {
                      return GifMessageWidget(gifUrl: message.content);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              InputWidget(
                  onBlurred: toggleEmojiKeyboard,
                  controller: _textController,
                  isEmojiVisible: isEmojiVisible,
                  isKeyboardVisible: isKeyboardVisible,
                  focusNode: focusNode,
                  onSentMessage: (message) {
                    _sendMessage(message);
                  }),
              Offstage(
                offstage: !isEmojiVisible,
                child: EmojiGifPicker(
                  onEmojiSelected: onEmojiSelected,
                  onGifSelected: _sendGif,
                  gifsToDisplay: trendingGifs,
                ),
              ),
            ],
          ),
        ),
      );

  void onEmojiSelected(String emoji) => setState(() {
        _textController.text = _textController.text + emoji;
      });

  Future toggleEmojiKeyboard() async {
    if (isKeyboardVisible) {
      focusNode.unfocus();
      // FocusScope.of(context).unfocus();
    }

    setState(() {
      isEmojiVisible = !isEmojiVisible;
    });
  }

  void _sendMessage(String message) {
    setState(() {
      messages.insert(0, Message(type: MessageType.text, content: message));
    });
  }

  void _sendGif(String gifUrl) {
    setState(() {
      messages.insert(0, Message(type: MessageType.gif, content: gifUrl));
    });
  }

  Future<List<GiphyGif>> _fetchTrendingGifs() async {
    final client = GiphyClient(apiKey: 'iAvrIIhwmqh7L4ULCeoI6gYYl1TxsAvt');
    final result = await client.trending();
    return result.data;
  }
}

class InputWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isEmojiVisible;
  final bool isKeyboardVisible;
  final Function onBlurred;
  final ValueChanged<String> onSentMessage;
  final FocusNode focusNode;

  const InputWidget({
    required this.controller,
    required this.isEmojiVisible,
    required this.isKeyboardVisible,
    required this.onSentMessage,
    required this.onBlurred,
    required this.focusNode,
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
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: IconButton(
                icon: Icon(
                  isEmojiVisible
                      ? Icons.keyboard_rounded
                      : Icons.emoji_emotions_outlined,
                ),
                onPressed: onClickedEmoji,
              ),
            ),
            Expanded(
              child: TextField(
                focusNode: focusNode,
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (value) => _sendAndClear(),
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            Container(
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
            )
          ],
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

  void _sendAndClear() async {
    if (controller.text.isNotEmpty) {
      onSentMessage(controller.text);
      controller.clear();
      focusNode.unfocus();
    }
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
        Flexible(
          child: Container(
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
        ),
      ],
    );
  }
}

class EmojiGifPicker extends StatefulWidget {
  final ValueChanged<String> onEmojiSelected;
  final Future<List<GiphyGif>>? gifsToDisplay;
  final Function(String) onGifSelected;
  const EmojiGifPicker({
    super.key,
    required this.onEmojiSelected,
    required this.gifsToDisplay,
    required this.onGifSelected,
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
              FutureBuilder<List<GiphyGif>>(
                future: widget.gifsToDisplay,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CupertinoActivityIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Error loading GIFs'));
                  } else {
                    final gifs = snapshot.data!;
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: gifs.length,
                      itemBuilder: (context, index) {
                        final gif = gifs[index];
                        return GestureDetector(
                          onTap: () =>
                              widget.onGifSelected(gif.images.original!.url!),
                          child: CachedNetworkImage(
                            imageUrl: gif.images.fixedWidth!.url!,
                            placeholder: (context, url) =>
                                const CupertinoActivityIndicator(),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        );
                      },
                    );
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class GifMessageWidget extends StatelessWidget {
  final String gifUrl;

  const GifMessageWidget({
    super.key,
    required this.gifUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.all(8.0),
      child: CachedNetworkImage(
        imageUrl: gifUrl,
        placeholder: (context, url) => const CupertinoActivityIndicator(),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }
}
