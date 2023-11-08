import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share/share.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klibat Dog breeds',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DogBreedsScreen(),
    );
  }
}

class DogBreedsScreen extends StatefulWidget {
  @override
  _DogBreedsScreenState createState() => _DogBreedsScreenState();
}

class _DogBreedsScreenState extends State<DogBreedsScreen> {
  List<String> breeds = [];
  String searchBreed = '';

  @override
  void initState() {
    super.initState();
    fetchDogBreeds();
  }

  Future<void> fetchDogBreeds() async {
    final response =
        await http.get(Uri.parse('https://dog.ceo/api/breeds/list/all'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final message = data['message'];
      setState(() {
        breeds = message.keys.toList();
      });
    }
  }

  void searchBreedChanged(String value) {
    setState(() {
      searchBreed = value;
    });
  }

  List<String> getFilteredBreeds() {
    if (searchBreed.isEmpty) {
      return breeds;
    } else {
      return breeds
          .where((breed) =>
              breed.toLowerCase().contains(searchBreed.toLowerCase()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBreeds = getFilteredBreeds();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: searchBreedChanged,
          decoration: InputDecoration(
            hintText: 'Search Breed',
            hintStyle: TextStyle(color: Colors.white),
          ),
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: filteredBreeds.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DogImagesScreen(breed: filteredBreeds[index]),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildDogImageWidget(filteredBreeds[index]),
                  SizedBox(height: 10),
                  Text(
                    filteredBreeds[index],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildDogImageWidget(String breed) {
    return FutureBuilder<List<String>>(
      future: fetchDogImages(breed),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error loading image');
        } else {
          final images = snapshot.data!;

          if (images.isNotEmpty) {
            return Image.network(
              images[0],
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.network(
                  images[images.length - 1],
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Text('Failed to load image');
                  },
                );
              },
            );
          }
          return Image.network(
            images[0],
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Text('Failed to load image');
            },
          );
        }
      },
    );
  }

  Future<List<String>> fetchDogImages(String breed) async {
    final response =
        await http.get(Uri.parse('https://dog.ceo/api/breed/$breed/images'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final message = data['message'];
      return List<String>.from(message);
    } else {
      throw Exception('Failed to fetch dog images');
    }
  }
}

class DogImagesScreen extends StatefulWidget {
  final String breed;

  DogImagesScreen({required this.breed});

  @override
  _DogImagesScreenState createState() => _DogImagesScreenState();
}

class _DogImagesScreenState extends State<DogImagesScreen> {
  List<String> images = [];
  bool isImageLoading = true;
  bool isImageLoadFailed = false;

  @override
  void initState() {
    super.initState();
    fetchDogImages();
  }

  Future<void> fetchDogImages() async {
    final response = await http
        .get(Uri.parse('https://dog.ceo/api/breed/${widget.breed}/images'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final message = data['message'];
      setState(() {
        images = List<String>.from(message);
        isImageLoading = true; // Set the loading state to true
      });
    } else {
      setState(() {
        isImageLoadFailed = true; // Set the image load failed state to true
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dog Images - ${widget.breed}'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: images.length,
        itemBuilder: (BuildContext context, int index) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      children: [
                        Text('Failed to load image'),
                        SizedBox(height: 10),
                      ],
                    );
                  },
                ),
                SizedBox(height: 10),
                if (!isImageLoading && !isImageLoadFailed)
                  ElevatedButton(
                    onPressed: () {
                      Share.share(images[index]);
                    },
                    child: Text('Share'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
