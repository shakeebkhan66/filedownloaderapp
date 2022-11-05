import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: MyHomePage(title: 'Flutter Downloading Files App'),
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

  ReceivePort receivePort = ReceivePort();
  int progress = 0;
  TextEditingController linkController = TextEditingController();
  String? link;

  void _downloadFile() async{
    var status = await Permission.storage.request();
    if(status.isDenied){
      Permission.storage.request();
    }else if(status.isGranted){

      final baseStorage = await getExternalStorageDirectory();


      print("Link $link");

      final taskId = await FlutterDownloader.enqueue(
        url: link.toString(),
        savedDir: baseStorage!.path,
        fileName: "filename",
      );

    }else{
      print("Permission is Denied, Change the permission from your mobile setting");
    }
  }



  @override
  void initState() {

    IsolateNameServer.registerPortWithName(receivePort.sendPort, 'downloadingVideo');
    receivePort.listen((message) {
      setState(() {
        progress = message;
      });
    });

    FlutterDownloader.registerCallback(downloadCallBack);
    super.initState();
  }

  static downloadCallBack(id, status, progress) {
    SendPort? sendPort = IsolateNameServer.lookupPortByName('downloadingVideo');
    sendPort!.send(progress);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: TextFormField(
                controller: linkController,
                decoration: const InputDecoration(
                  hintText: "Paste link of video",
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.limeAccent),
                  )
                ),
              ),
            ),

            MaterialButton(
              onPressed: (){
                link = linkController.text;
                print("Link $link");
                _downloadFile();
              },
              color: Colors.green,
              child: Text("Download", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
            ),

            const SizedBox(height: 50,),
            const Text(
              'Downloading Percentage',
            ),
            Text(
              '$progress',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _downloadFile,
        tooltip: 'Downloading',
        child: const Icon(Icons.download),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
