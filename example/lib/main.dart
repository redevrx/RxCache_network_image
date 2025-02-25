import 'package:flutter/material.dart';
import 'package:rxcache_network_image/rxcache_network_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final cacheManager = RxCacheManager();
  final showList = ValueNotifier(true);
  bool allowLoad = true;
  final items = [
    "https://images.pexels.com/photos/18280488/pexels-photo-18280488.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
    "https://images.pexels.com/photos/19564349/pexels-photo-19564349.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
  ];

  @override
  void didChangeDependencies() async {
    for (var element in urls) {
      cacheManager.download(url: element);
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    showList.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          SizedBox(
            height: 600,
            width: double.infinity,
            child: ValueListenableBuilder(
              valueListenable: showList,
              builder: (context, value, child) {
                return value
                    ? NotificationListener<ScrollNotification>(
                      onNotification: (details) {
                        if (details.metrics.pixels ==
                            details.metrics.maxScrollExtent) {
                          if (allowLoad) {
                            loadMore();
                          }
                        }

                        return true;
                      },
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return RxImage.cacheNetwork(
                            url: items[index],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            height: 300,
                          );
                        },
                      ),
                    )
                    : const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          showList.value = !showList.value;
        },
      ),
    );
  }

  void loadMore() async {
    allowLoad = false;
    await Future.delayed(const Duration(milliseconds: 750), () {
      debugPrint("wait preload");
    });

    for (final url in urls) {
      cacheManager.download(url: url);
    }

    setState(() {
      items.addAll(urls);
    });
  }
}

const urls = [
  "https://images.pexels.com/photos/19560944/pexels-photo-19560944.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
  "https://images.pexels.com/photos/17889085/pexels-photo-17889085.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
  "https://images.pexels.com/photos/19542480/pexels-photo-19542480.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
  "https://images.pexels.com/photos/18325566/pexels-photo-18325566.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
  "https://images.pexels.com/photos/3509971/pexels-photo-3509971.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
  "https://images.pexels.com/photos/1998435/pexels-photo-1998435.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
  "https://images.pexels.com/photos/19784853/pexels-photo-19784853.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
  "https://images.pexels.com/photos/16844098/pexels-photo-16844098.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
  "https://images.pexels.com/photos/19616595/pexels-photo-19616595.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
  "https://images.pexels.com/photos/13280779/pexels-photo-13280779.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
  "https://images.pexels.com/photos/10977781/pexels-photo-10977781.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
  "https://images.pexels.com/photos/18709783/pexels-photo-18709783.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
  "https://images.pexels.com/photos/19677280/pexels-photo-19677280.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
  "https://images.pexels.com/photos/16123335/pexels-photo-16123335.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
  "https://images.pexels.com/photos/7345169/pexels-photo-7345169.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
  "https://images.pexels.com/photos/14728280/pexels-photo-14728280.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
  "https://images.pexels.com/photos/19724635/pexels-photo-19724635.png?auto=compress&cs=tinysrgb&w=1200&lazy=load",
  "https://images.pexels.com/photos/5738986/pexels-photo-5738986.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
  "https://images.pexels.com/photos/19696637/pexels-photo-19696637.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
  "https://images.pexels.com/photos/19540163/pexels-photo-19540163.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
  "https://images.pexels.com/photos/19789102/pexels-photo-19789102.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
];
