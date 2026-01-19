import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_theme.dart';
import '../models/plate_result.dart';
import '../services/api_service.dart';
import '../widgets/animated_primary_button.dart';
import '../widgets/premium_loader.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _picker = ImagePicker();
  final _apiService = ApiService();

  PlateResult? _result;
  String? _imagePath;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _contentController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeIn = CurvedAnimation(parent: _contentController, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOut));
    _contentController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickAndDetect(ImageSource source) async {
    setState(() {
      _errorMessage = null;
    });

    final image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      _imagePath = image.path;
      _isLoading = true;
      _result = null;
    });

    try {
      final detection = await _apiService.detectPlate(image.path);
      if (!mounted) return;

      setState(() {
        _result = detection;
      });

      _contentController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      final message = _friendlyError(e);

      setState(() {
        _errorMessage = message;
      });

      _showError(message);
      _shakeScaffold();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startCaptureFlow() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _PickSourceSheet(),
    );
    if (!mounted || source == null) return;
    await _pickAndDetect(source);
  }

  String _friendlyError(Object e) {
    final raw = e.toString();
    if (raw.contains('SocketException')) {
      return 'Tidak bisa terhubung. Cek koneksi internet.';
    }
    return 'Deteksi gagal. Coba lagi.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  late final GlobalKey<_ShakeScaffoldState> _shakeKey =
      GlobalKey<_ShakeScaffoldState>();

  void _shakeScaffold() => _shakeKey.currentState?.shake();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _ShakeScaffold(
      key: _shakeKey,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('Deteksi Plat Nomor', style: textTheme.titleLarge),
          actions: [
            IconButton(
              tooltip: 'Pilih foto',
              onPressed: _isLoading ? null : _startCaptureFlow,
              icon: const Icon(Icons.photo_camera_rounded),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: AnimatedPrimaryButton(
            onPressed: _isLoading ? null : _startCaptureFlow,
            icon: const Icon(Icons.camera_alt_rounded),
            label: _isLoading ? 'Memproses…' : 'Pilih Foto',
          ),
        ),
        body: Stack(
          children: [
            const _Background(),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideIn,
                    child: _Body(
                      imagePath: _imagePath,
                      isLoading: _isLoading,
                      result: _result,
                      errorMessage: _errorMessage,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickSourceSheet extends StatelessWidget {
  const _PickSourceSheet();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pilih sumber', style: textTheme.titleLarge),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Kamera'),
                  subtitle: const Text('Ambil foto'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Galeri'),
                  subtitle: const Text('Pilih dari galeri'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pastikan plat terlihat jelas.',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF6F7FB),
            Color(0xFFF3F7FF),
            Color(0xFFF2FFFB),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: _GlowBlob(color: AppTheme.primary.withOpacity(0.22)),
          ),
          Positioned(
            bottom: -90,
            left: -90,
            child: _GlowBlob(color: AppTheme.secondary.withOpacity(0.18)),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;

  const _GlowBlob({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 80,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String? imagePath;
  final bool isLoading;
  final PlateResult? result;
  final String? errorMessage;

  const _Body({
    required this.imagePath,
    required this.isLoading,
    required this.result,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Mulai deteksi',
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Pilih foto dari kamera atau galeri.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: child,
                ),
              );
            },
            child: isLoading
                ? const _CenterKeyed(
                    key: ValueKey('loading'),
                    child: PremiumLoader(label: 'Mendeteksi…'),
                  )
                : (result == null)
                    ? _CenterKeyed(
                        key: const ValueKey('empty'),
                        child: _EmptyState(
                          hasImage: imagePath != null,
                          errorMessage: errorMessage,
                        ),
                      )
                    : _ResultView(
                        key: const ValueKey('result'),
                        result: result!,
                        imagePath: imagePath,
                      ),
          ),
        ),
      ],
    );
  }
}

class _CenterKeyed extends StatelessWidget {
  final Widget child;

  const _CenterKeyed({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(child: child);
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasImage;
  final String? errorMessage;

  const _EmptyState({required this.hasImage, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: AppTheme.heroGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 46,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada hasil',
            style: textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            hasImage
                ? 'Belum ada hasil. Coba lagi.'
                : 'Pilih foto untuk mulai.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            _InfoPill(
              icon: Icons.info_outline_rounded,
              text: errorMessage!,
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final PlateResult result;
  final String? imagePath;

  const _ResultView({super.key, required this.result, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final confidencePct = (result.confidence * 100).clamp(0, 100).toDouble();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Hasil', style: textTheme.titleLarge),
                    ),
                    _StatusChip(
                      ok: confidencePct >= 55,
                      label: confidencePct >= 55 ? 'Terdeteksi' : 'Kurang yakin',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (imagePath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.file(
                        File(imagePath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: colorScheme.primary.withOpacity(0.06),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.heroGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.confirmation_number_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Plat Nomor', style: textTheme.bodyMedium),
                            const SizedBox(height: 2),
                            Text(
                              result.formattedPlate,
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _KeyValue(
                  label: 'Daerah',
                  value: result.daerah ?? 'Tidak terdeteksi',
                  icon: Icons.place_rounded,
                ),
                _KeyValue(
                  label: 'Provinsi',
                  value: result.provinsi ?? 'Tidak terdeteksi',
                  icon: Icons.map_rounded,
                ),
                _KeyValue(
                  label: 'Alamat Samsat',
                  value: result.alamatSamsat ?? '-',
                  icon: Icons.apartment_rounded,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _InfoPill(
          icon: Icons.tips_and_updates_rounded,
          text: 'Tips: pastikan foto terang dan tidak blur.',
        ),
      ],
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _KeyValue({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.secondary.withOpacity(0.08),
        border: Border.all(color: colorScheme.secondary.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool ok;
  final String label;

  const _StatusChip({required this.ok, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppTheme.secondary : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ShakeScaffold extends StatefulWidget {
  final Widget child;

  const _ShakeScaffold({super.key, required this.child});

  @override
  State<_ShakeScaffold> createState() => _ShakeScaffoldState();
}

class _ShakeScaffoldState extends State<_ShakeScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  late final Animation<double> _dx = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -10, end: 8), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -6, end: 4), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  void shake() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dx,
      builder: (context, child) => Transform.translate(
        offset: Offset(_dx.value, 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}
