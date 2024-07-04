import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageGallery extends StatefulWidget {
  const ImageGallery({super.key});

  @override
  ImageGalleryState createState() => ImageGalleryState();
}

class ImageGalleryState extends State<ImageGallery> {
  List<String> images = List.generate(60, (id) {
    return 'https://picsum.photos/id/${id * 10}/1200/1200';
  });

  bool isGridView = false;
  bool isFullScreen = false;
  int currentIndex = 0;
  double? initialScale;
  double gridScrollOffset = 0;
  int crossAxisCount = 2;

  late PhotoViewController photoViewController;
  late PageController pageController;
  late ScrollController gridScrollController;

  ReadingMode readingMode = ReadingMode.leftToRight;

  @override
  void initState() {
    super.initState();
    photoViewController = PhotoViewController()
      ..outputStateStream.listen(onController);
    pageController = PageController(initialPage: currentIndex);
    gridScrollController = ScrollController();
  }

  void onController(PhotoViewControllerValue value) {
    initialScale ??= value.scale;
    _showGrid(value.scale);
  }

  @override
  void dispose() {
    photoViewController.dispose();
    pageController.dispose();
    gridScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isFullScreen
          ? null
          : AppBar(
              title: Text('Photo View Gallery | ${currentIndex + 1}'),
            ),
      body: Column(
        children: [
          Expanded(
            child: isGridView ? buildGridView() : buildPhotoViewGallery(),
          ),
          if (!isFullScreen) buildControlPanel(),
        ],
      ),
    );
  }

  Widget buildGridView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollEndNotification) {
          gridScrollOffset = gridScrollController.offset;
        }
        return false;
      },
      child: GridView.builder(
        controller: gridScrollController,
        itemCount: images.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
        ),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTapDown: (_) {
              setState(() {
                currentIndex = index;
                isGridView = false;
                pageController = PageController(initialPage: currentIndex);
              });
            },
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: currentIndex == index
                          ? Colors.yellow
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: images[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CupertinoActivityIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      (index + 1).toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildPhotoViewGallery() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isFullScreen = !isFullScreen;
        });
      },
      child: PageView.builder(
        scrollDirection: readingMode == ReadingMode.topToBottom
            ? Axis.vertical
            : Axis.horizontal,
        reverse: readingMode == ReadingMode.rightToLeft,
        controller: pageController,
        onPageChanged: (value) => setState(() => currentIndex = value),
        itemBuilder: (context, index) {
          return PhotoView(
            imageProvider: CachedNetworkImageProvider(images[index]),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            controller: photoViewController,
            minScale: PhotoViewComputedScale.contained * 1.0,
            maxScale: PhotoViewComputedScale.covered * 5.0,
            initialScale: PhotoViewComputedScale.contained,
            basePosition: Alignment.center,
            loadingBuilder: (context, event) => Container(
              color: Colors.black,
              child: const Center(
                child: CupertinoActivityIndicator(),
              ),
            ),
            gaplessPlayback: true,
          );
        },
      ),
    );
  }

  Widget buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          buildReadingModeButton(
            text: "LTR",
            mode: ReadingMode.leftToRight,
            icon: Icons.swap_horiz,
          ),
          buildReadingModeButton(
            text: "RTL",
            mode: ReadingMode.rightToLeft,
            icon: Icons.swap_horiz,
          ),
          buildReadingModeButton(
            text: "TTB",
            mode: ReadingMode.topToBottom,
            icon: Icons.swap_vert,
          ),
        ],
      ),
    );
  }

  Widget buildReadingModeButton({
    required String text,
    required ReadingMode mode,
    required IconData icon,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: readingMode == mode ? Colors.blue : Colors.grey,
      ),
      onPressed: () {
        setState(() {
          readingMode = mode;
        });
      },
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 4),
          Text(text),
        ],
      ),
    );
  }

  void _showGrid(double? scale) {
    if (scale != null) {
      if (scale < (initialScale ?? 1.0)) {
        setState(() {
          isGridView = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToCurrentIndex();
          });
        });
      }
    }
  }

  void _scrollToCurrentIndex() {
    final double itemHeight =
        MediaQuery.of(context).size.width / crossAxisCount;
    final int row = currentIndex ~/ crossAxisCount;
    final double offset = row * itemHeight -
        (MediaQuery.of(context).size.height / 2) +
        (itemHeight / 2);

    gridScrollController.jumpTo(offset);
  }
}

enum ReadingMode {
  leftToRight,
  rightToLeft,
  topToBottom,
}
