import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
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
      body: Column(
        children: [
          Expanded(
            child: CarouselSlider(
              items: filteredBreeds.map((breed) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DogImagesScreen(breed: breed),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        buildDogImageWidget(breed),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Text(
                            breed,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              options: CarouselOptions(
                aspectRatio: 16 / 16,
                // Adjust the aspect ratio to control the size of each item
                enlargeCenterPage: true,
                // Enable to make the current item larger
                enableInfiniteScroll: true,
                // Enable to loop through the items infinitely
                autoPlay: true,
                // Enable to automatically scroll through the items
                autoPlayInterval: Duration(
                    seconds: 5), // Adjust the interval between auto-scrolls
              ),
            ),
          ),
        ],
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
              width: 400,
              height: 400,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                return Image.network(
                  images[images.length - 1],
                  width: 400,
                  height: 400,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) {
                    return Text('Failed to load image');
                  },
                );
              },
            );
          }
          return Image.network(
            images[0],
            width: 400,
            height: 400,
            fit: BoxFit.fill,
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
        title: Text('${widget.breed} Images'),
      ),
      body: Center(
        child: CarouselSlider.builder(
          itemCount: images.length,
          itemBuilder: (BuildContext context, int index, int realIndex) {
            return Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Image.network(
                        images[index],
                        width: 400,
                        height: 400,
                        fit: BoxFit.fill,
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
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ElevatedButton(
                      onPressed: () {
                        Share.share(images[index]);
                      },
                      child: Text('Share'),
                    ),
                  ),
                ),
              ],
            );
          },
          options: CarouselOptions(
            aspectRatio: 16 / 18,
            // Adjust the aspect ratio to control the size of each item
            enlargeCenterPage: true,
            // Enable to make the current item larger
            enableInfiniteScroll: true,
            // Enable to loop through the items infinitely
            autoPlay: true,
            // Disable auto-scrolling
          ),
        ),
      ),
    );
  }
}
