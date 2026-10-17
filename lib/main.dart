
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music Player',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MusicScreen(),
    );
  }
}

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _hasPermission = false;
  String? _currentPlayingSong;

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  void requestPermission() async {
    // សុំសិទ្ធិអាន Storage ក្នុងទូរស័ព្ទ
    PermissionStatus status = await Permission.storage.request();
    if (!status.isGranted) {
      status = await Permission.audio.request();
    }
    setState(() {
      _hasPermission = status.isGranted;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Music Player (.mp3, .m4a, .wav)'),
      ),
      body: !_hasPermission
          ? const Center(
              child: Text(
                'សូមផ្ដល់សិទ្ធិអាន File ក្នុងទូរស័ព្ទដើម្បីបង្ហាញចម្រៀង!',
                textAlign: TextAlign.center,
              ),
            )
          : FutureBuilder<List<SongModel>>(
              future: _audioQuery.querySongs(
                sortType: SongSortType.TITLE,
                orderType: OrderType.ASC_OR_SMALLER,
                uriType: UriType.EXTERNAL,
                ignoreCase: true,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('រកមិនឃើញបទចម្រៀងក្នុងទូរស័ព្ទទេ។'),
                  );
                }

                List<SongModel> songs = snapshot.data!;
                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    song = songs[index];
                    return ListTile(
                      leading: QueryArtworkWidget(
                        controller: _audioQuery,
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: const Icon(Icons.music_note, size: 50),
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.artist ?? "<Unknown>",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () async {
                          try {
                            await _audioPlayer.setAudioSource(
                              AudioSource.uri(Uri.parse(song.data)),
                            );
                            _audioPlayer.play();
                            setState(() {
                              _currentPlayingSong = song.title;
                            });
                          } catch (e) {
                            print("Error playing audio: $e");
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: _currentPlayingSong != null
          ? Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade100,
              child: Text(
                'កំពុងចាក់: $_currentPlayingSong',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            )
          : null,
    );
  }
}
