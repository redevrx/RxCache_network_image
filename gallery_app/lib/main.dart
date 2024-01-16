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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final items = [
    "https://images.pexels.com/photos/19560944/pexels-photo-19560944.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
    "https://images.pexels.com/photos/18280488/pexels-photo-18280488.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
    "https://images.pexels.com/photos/19564349/pexels-photo-19564349.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
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
  ];
  int page = 1;
  bool isAllowLoad = true;

  ///try remove preload
  void loadMore() async {
    isAllowLoad = false;
    if (page == 1) {
      final urls = [
        'https://farm4.staticflickr.com/3075/3168662394_7d7103de7d_z_d.jpg',
        'https://farm2.staticflickr.com/1533/26541536141_41abe98db3_z_d.jpg',
        'https://i.imgur.com/CzXTtJV.jpg',
        "https://images.pexels.com/photos/16123335/pexels-photo-16123335.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
        "https://images.pexels.com/photos/7345169/pexels-photo-7345169.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
        "https://images.pexels.com/photos/14728280/pexels-photo-14728280.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
        "https://images.pexels.com/photos/19724635/pexels-photo-19724635.png?auto=compress&cs=tinysrgb&w=1200&lazy=load",
        "https://images.pexels.com/photos/5738986/pexels-photo-5738986.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
        "https://images.pexels.com/photos/19696637/pexels-photo-19696637.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
        "https://images.pexels.com/photos/19540163/pexels-photo-19540163.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load",
        "https://images.pexels.com/photos/19789102/pexels-photo-19789102.jpeg?auto=compress&cs=tinysrgb&w=1200&lazy=load"
      ];

      // await preload(urls);

      setState(() {
        items.addAll(urls);
        page++;
      });
    }
    if (page == 2) {
      final urls = [
        'https://images.pexels.com/photos/1056251/pexels-photo-1056251.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/2071873/pexels-photo-2071873.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/1170986/pexels-photo-1170986.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/45201/kitty-cat-kitten-pet-45201.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://farm4.staticflickr.com/3752/9684880330_9b4698f7cb_z_d.jpg',
        'https://farm2.staticflickr.com/1449/24800673529_64272a66ec_z_d.jpg',
        'https://farm9.staticflickr.com/8295/8007075227_dc958c1fe6_z_d.jpg',
        'https://farm8.staticflickr.com/7377/9359257263_81b080a039_z_d.jpg',
        'https://farm4.staticflickr.com/3224/3081748027_0ee3d59fea_z_d.jpg',
        'https://farm2.staticflickr.com/1090/4595137268_0e3f2b9aa7_z_d.jpg',
        'https://farm7.staticflickr.com/6089/6115759179_86316c08ff_z_d.jpg',
        'https://images.pexels.com/photos/321552/pexels-photo-321552.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://farm3.staticflickr.com/2220/1572613671_7311098b76_z_d.jpg',
        'https://i.imgur.com/OnwEDW3.jpg',
      ];

      // await preload(urls);

      setState(() {
        items.addAll(urls);
        page++;
      });
    }
    if (page == 3) {
      final urls = [
        'https://images.pexels.com/photos/1383044/pexels-photo-1383044.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/2537951/pexels-photo-2537951.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/2529369/pexels-photo-2529369.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/4096517/pexels-photo-4096517.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/425133/pexels-photo-425133.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/1441454/pexels-photo-1441454.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/922521/pexels-photo-922521.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/3445161/pexels-photo-3445161.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/3280908/pexels-photo-3280908.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/3281127/pexels-photo-3281127.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/80474/grass-snake-snake-serpentes-natrix-80474.jpeg?auto=compress&cs=tinysrgb&w=1200',
      ];

      // await preload(urls);

      setState(() {
        items.addAll(urls);
        page++;
      });
    }
    if (page == 4) {
      final urls = [
        'https://images.pexels.com/photos/10646413/pexels-photo-10646413.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/162140/duckling-birds-yellow-fluffy-162140.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/52500/horse-herd-fog-nature-52500.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/1108099/pexels-photo-1108099.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/62289/yemen-chameleon-chamaeleo-calyptratus-chameleon-reptile-62289.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/1784578/pexels-photo-1784578.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/416160/pexels-photo-416160.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/325045/pexels-photo-325045.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/18584297/pexels-photo-18584297/free-photo-of-full-size-mecha-from-the-mobile-suit-gundam-anime-in-entertainment-complex-in-yokohama.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/5905356/pexels-photo-5905356.jpeg?auto=compress&cs=tinysrgb&w=1200',
        'https://images.pexels.com/photos/15964921/pexels-photo-15964921/free-photo-of-close-up-of-a-figurine-of-an-anime-character.jpeg?auto=compress&cs=tinysrgb&w=1200',
      ];

      // await preload(urls);

      setState(() {
        items.addAll(urls);
        page++;
      });
    }

    setState(() {
      isAllowLoad = page != 5;
    });
  }

  Future<void> preload(List<String> urls) async {
    for (final url in urls) {
      RxCacheManager().download(url: url);
    }
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Gallery App with RxImage",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (details) {
                if (details.metrics.pixels >=
                    details.metrics.maxScrollExtent - 200) {
                  if (isAllowLoad) {
                    loadMore();
                  }
                }
                return true;
              },
              child: GridView.builder(
                itemCount: isAllowLoad ? items.length + 1 : items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: .9,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemBuilder: (context, index) {
                  if (index < items.length) {
                    return RxImage.cacheNetwork(
                      url: items[index],
                      fit: BoxFit.cover,
                    );
                  } else {
                    return const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                      ],
                    );
                  }
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
