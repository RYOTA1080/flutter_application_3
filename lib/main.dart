import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

const token = 'PXZdwXG9vRzSmR7resPzCeMOw5FUvz76SgkdUfbT';

final getIt = GetIt.instance;

class TokenInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Api-Key'] = token;
    handler.next(options);
  }
}

void main() {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.api-ninjas.com/v1/'));
  dio.interceptors.add(TokenInterceptor());
  dio.interceptors.add(PrettyDioLogger(requestHeader: true));
  getIt.registerSingleton<Dio>(dio);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.orange),
      home: const CatsPage(),
    ),
  );
}

Widget catImage(String url, double size) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
    ),
  );
}

class CatsPage extends StatefulWidget {
  const CatsPage({super.key});

  @override
  State<CatsPage> createState() => _CatsPageState();
}

class _CatsPageState extends State<CatsPage> {
  final controller = TextEditingController();
  List cats = [];
  bool loading = false;
  String message = 'Введите название породы';

  Future<void> search() async {
    if (controller.text.isEmpty) return;
    setState(() {
      loading = true;
      cats = [];
      message = '';
    });
    try {
      final response = await getIt<Dio>().get('cats', queryParameters: {'name': controller.text});
      cats = response.data;
      if (cats.isEmpty) message = 'Ничего не найдено';
    } catch (e) {
      message = 'Ошибка загрузки';
    }
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Породы кошек')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              onSubmitted: (_) => search(),
              decoration: InputDecoration(
                hintText: 'Например: siamese',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: search),
              ),
            ),
          ),
          if (loading) const CircularProgressIndicator(),
          Text(message),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cats.length,
              itemBuilder: (context, index) {
                final cat = cats[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: catImage(cat['image_link'], 56),
                    title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(cat['origin']),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CatPage(cat: cat)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CatPage extends StatelessWidget {
  final Map cat;

  const CatPage({super.key, required this.cat});

  Widget row(String title, String value) {
    return ListTile(title: Text(title), trailing: Text(value));
  }

  Widget stars(String title, int value) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        '★' * value + '☆' * (5 - value),
        style: const TextStyle(color: Colors.orange, fontSize: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(cat['name'])),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: catImage(cat['image_link'], 300)),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                row('Происхождение', cat['origin']),
                row('Длина', cat['length']),
                row('Вес, фунты', '${cat['min_weight']} - ${cat['max_weight']}'),
                row('Жизнь, лет', '${cat['min_life_expectancy']} - ${cat['max_life_expectancy']}'),
                stars('Игривость', cat['playfulness']),
                stars('Дружелюбие к детям', cat['children_friendly']),
                stars('Интеллект', cat['intelligence']),
                stars('Здоровье', cat['general_health']),
                stars('Линька', cat['shedding']),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
