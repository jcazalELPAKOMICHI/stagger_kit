import 'package:flutter/material.dart';
import 'package:stagger_kit/stagger_kit.dart';

void main() => runApp(const StaggerKitDemo());

class StaggerKitDemo extends StatelessWidget {
  const StaggerKitDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'stagger_kit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        brightness: Brightness.dark,
      ),
      home: const DemoHome(),
    );
  }
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  int _tab = 0;

  // A new key per visit rebuilds the page, so its entrance plays again.
  int _visit = 0;

  @override
  Widget build(BuildContext context) {
    final page = switch (_tab) {
      0 => LoginDemo(key: ValueKey(_visit)),
      1 => ListDemo(key: ValueKey(_visit)),
      _ => GridDemo(key: ValueKey(_visit)),
    };
    return Scaffold(
      body: SafeArea(child: page),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Replay',
        onPressed: () => setState(() => _visit++),
        child: const Icon(Icons.replay),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (tab) => setState(() {
          _tab = tab;
          _visit++;
        }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.login), label: 'Login'),
          NavigationDestination(icon: Icon(Icons.list), label: 'List'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Grid'),
        ],
      ),
    );
  }
}

/// The login cascade: every block fades up one after another.
class LoginDemo extends StatelessWidget {
  const LoginDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(
            Icons.local_shipping_rounded,
            size: 96,
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 32),
        Text('Welcome back', style: text.headlineMedium),
        const SizedBox(height: 24),
        const TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.mail_outline),
            labelText: 'Email or phone',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline),
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(value: true, onChanged: (_) {}),
            const Text('Keep me signed in'),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text('Forgot password?')),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Log in'),
        ),
        const SizedBox(height: 24),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Google'),
              ),
            ),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.apple),
                label: const Text('Apple'),
              ),
            ),
          ],
        ),
      ].stagger(effects: StaggerPresets.focusUp),
    );
  }
}

/// A lazy list: visible rows cascade in, rows reached by scrolling just appear.
class ListDemo extends StatelessWidget {
  const ListDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return StaggerScope(
      effects: StaggerPresets.slideFromRight,
      child: ListView.builder(
        itemCount: 50,
        itemBuilder: (context, i) => ListTile(
          leading: CircleAvatar(child: Text('${i + 1}')),
          title: Text('Shipment #${1000 + i}'),
          subtitle: const Text('In transit'),
          trailing: const Icon(Icons.chevron_right),
        ).staggerAt(i),
      ),
    );
  }
}

/// A grid that cascades diagonally, row plus column.
class GridDemo extends StatelessWidget {
  const GridDemo({super.key});

  static const _columns = 3;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StaggerScope(
      effects: StaggerPresets.pop,
      interval: const Duration(milliseconds: 60),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: 30,
        itemBuilder: (context, i) => DecoratedBox(
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(child: Text('${i + 1}')),
        ).staggerAt(i, columnCount: _columns),
      ),
    );
  }
}
