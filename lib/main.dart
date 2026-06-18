import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const TornadoGallerySite());

const _iosUrl = 'https://apps.apple.com/us/app/tornado-gallery/id6779098273';
const _androidUrl =
    'https://play.google.com/store/apps/details?id=com.flockit.tornadogallery';

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    debugPrint('Could not launch $url');
  }
}

/// ----------------------------------------------------------------------------
/// Palette — mirrors the design's CSS custom properties for dark / light.
/// ----------------------------------------------------------------------------
class Palette {
  final Color bg,
      bg2,
      surface,
      surface2,
      border,
      text,
      muted,
      accent,
      amber,
      glow,
      card,
      shadow;
  final bool isDark;

  const Palette({
    required this.bg,
    required this.bg2,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.amber,
    required this.glow,
    required this.card,
    required this.shadow,
    required this.isDark,
  });

  static const dark = Palette(
    bg: Color(0xFF06141A),
    bg2: Color(0xFF0A1F27),
    surface: Color(0x0BFFFFFF), // rgba(255,255,255,0.045)
    surface2: Color(0x12FFFFFF), // rgba(255,255,255,0.07)
    border: Color(0x1AFFFFFF), // rgba(255,255,255,0.10)
    text: Color(0xFFE9F2F1),
    muted: Color(0xFF90A9AD),
    accent: Color(0xFF36D6D0),
    amber: Color(0xFFF5B833),
    glow: Color(0x5236D6D0), // rgba(54,214,208,0.32)
    card: Color(0x9E09181E), // rgba(9,24,30,0.62)
    shadow: Color(0x80000000),
    isDark: true,
  );

  static const light = Palette(
    bg: Color(0xFFEEF3F1),
    bg2: Color(0xFFE3EBE8),
    surface: Color(0xB8FFFFFF), // rgba(255,255,255,0.72)
    surface2: Color(0xFFFFFFFF),
    border: Color(0x1F08282D), // rgba(8,40,45,0.12)
    text: Color(0xFF0C2329),
    muted: Color(0xFF4A636B),
    accent: Color(0xFF0E9B95),
    amber: Color(0xFFCF8D12),
    glow: Color(0x380E9B95), // rgba(14,155,149,0.22)
    card: Color(0xB8FFFFFF), // rgba(255,255,255,0.72)
    shadow: Color(0x29143C41), // rgba(20,60,65,0.16)
    isDark: false,
  );
}

/// Shared fonts.
TextStyle grotesk({
  double? size,
  FontWeight? weight,
  Color? color,
  double? height,
  double? spacing,
}) => GoogleFonts.spaceGrotesk(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: spacing,
);
TextStyle plex({
  double? size,
  FontWeight? weight,
  Color? color,
  double? height,
}) => GoogleFonts.ibmPlexSans(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
);
TextStyle mono({
  double? size,
  FontWeight? weight,
  Color? color,
  double? height,
  double? spacing,
}) => GoogleFonts.jetBrainsMono(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: spacing,
);

/// ----------------------------------------------------------------------------
/// Inherited scope — exposes palette, theme toggle, and the scroll reveal hub.
/// ----------------------------------------------------------------------------
class SiteScope extends InheritedWidget {
  final Palette palette;
  final VoidCallback toggleTheme;
  final RevealHub revealHub;

  const SiteScope({
    super.key,
    required this.palette,
    required this.toggleTheme,
    required this.revealHub,
    required super.child,
  });

  static SiteScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SiteScope>()!;

  @override
  bool updateShouldNotify(SiteScope old) => old.palette != palette;
}

/// Lightweight scroll "tick" broadcaster for [Reveal] widgets.
class RevealHub extends ChangeNotifier {
  void tick() => notifyListeners();
}

/// ----------------------------------------------------------------------------
/// App root.
/// ----------------------------------------------------------------------------
class TornadoGallerySite extends StatefulWidget {
  const TornadoGallerySite({super.key});
  @override
  State<TornadoGallerySite> createState() => _TornadoGallerySiteState();
}

class _TornadoGallerySiteState extends State<TornadoGallerySite> {
  bool _dark = true;
  final _scroll = ScrollController();
  final _revealHub = RevealHub();

  void _toggleTheme() => setState(() => _dark = !_dark);

  @override
  void dispose() {
    _scroll.dispose();
    _revealHub.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _dark ? Palette.dark : Palette.light;
    return MaterialApp(
      title: 'Tornado Gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: _dark ? Brightness.dark : Brightness.light),
      home: SiteScope(
        palette: palette,
        toggleTheme: _toggleTheme,
        revealHub: _revealHub,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          color: palette.bg,
          child: NotificationListener<ScrollNotification>(
            onNotification: (_) {
              _revealHub.tick();
              return false;
            },
            child: Scrollbar(
              controller: _scroll,
              child: SingleChildScrollView(
                controller: _scroll,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: DefaultTextStyle(
                  style: plex(color: palette.text),
                  child: const _Page(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ----------------------------------------------------------------------------
/// Scroll-reveal wrapper (IntersectionObserver equivalent).
/// ----------------------------------------------------------------------------
class Reveal extends StatefulWidget {
  final Widget child;
  const Reveal({super.key, required this.child});
  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  bool _shown = false;
  RevealHub? _hub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hub == null) {
      _hub = SiteScope.of(context).revealHub..addListener(_check);
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  void _check() {
    if (_shown || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final y = box.localToGlobal(Offset.zero).dy;
    final h = MediaQuery.of(context).size.height;
    if (y < h * 0.92) {
      setState(() => _shown = true);
      _hub?.removeListener(_check);
    }
  }

  @override
  void dispose() {
    _hub?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _shown ? Offset.zero : const Offset(0, 0.16),
      duration: const Duration(milliseconds: 700),
      curve: const Cubic(.2, .7, .2, 1),
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: const Duration(milliseconds: 700),
        curve: const Cubic(.2, .7, .2, 1),
        child: widget.child,
      ),
    );
  }
}

/// ----------------------------------------------------------------------------
/// Glitch tile model + grid (the "encrypted noise" visual).
/// ----------------------------------------------------------------------------
class _Tile {
  final Color color;
  final double dur; // seconds
  final double delay; // seconds
  const _Tile(this.color, this.dur, this.delay);
}

final _rng = math.Random(7);
final List<Color> _tilePool = () {
  const weights = <int, int>{
    0xFF0A2A30: 9,
    0xFF0E3940: 9,
    0xFF114A52: 7,
    0xFF0A1F2E: 9,
    0xFF16313F: 7,
    0xFF0A1F24: 9,
    0xFF103038: 7,
    0xFF08323A: 7,
    0xFF1A9B9B: 3,
    0xFF36D6D0: 2,
    0xFFF5B833: 2,
    0xFFEEF5F4: 2,
  };
  final pool = <Color>[];
  weights.forEach((c, n) {
    for (var i = 0; i < n; i++) {
      pool.add(Color(c));
    }
  });
  return pool;
}();

List<_Tile> _makeTiles(int n) => List.generate(n, (_) {
  final c = _tilePool[_rng.nextInt(_tilePool.length)];
  final dur = 1.4 + _rng.nextDouble() * 3;
  final delay = _rng.nextDouble() * 4;
  return _Tile(c, dur, delay);
});

/// A flickering grid of tiles, driven by one shared controller.
class _GlitchGrid extends StatefulWidget {
  final int columns;
  final List<_Tile> tiles;
  const _GlitchGrid({required this.columns, required this.tiles});
  @override
  State<_GlitchGrid> createState() => _GlitchGridState();
}

class _GlitchGridState extends State<_GlitchGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * 8; // seconds within the 8s loop
        return GridView.count(
          crossAxisCount: widget.columns,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: widget.tiles.map((tile) {
            // tileFlicker: oscillate opacity via a sine wave per tile.
            final phase = ((t + tile.delay) / tile.dur) * math.pi;
            final s = (math.sin(phase) + 1) / 2; // 0..1
            final opacity = 0.62 + s * 0.38;
            return ColoredBox(color: tile.color.withValues(alpha: opacity));
          }).toList(),
        );
      },
    );
  }
}

/// ----------------------------------------------------------------------------
/// Page layout.
/// ----------------------------------------------------------------------------
class _Page extends StatelessWidget {
  const _Page();
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _Nav(),
        _Hero(),
        _ProblemSection(),
        _HowSection(),
        _FeaturesSection(),
        _PrivacyBand(),
        _DownloadCta(),
        _Footer(),
      ],
    );
  }
}

/// Centers content at max-width 1200 with horizontal padding.
class _Shell extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Shell({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 70),
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

bool _isNarrow(BuildContext c) => MediaQuery.of(c).size.width < 900;

/// ----------------------------------------------------------------------------
/// NAV
/// ----------------------------------------------------------------------------
class _Nav extends StatelessWidget {
  const _Nav();
  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    final narrow = _isNarrow(context);
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                const _Logo(size: 38, label: true),
                const Spacer(),
                if (!narrow) ...[
                  const _NavLink('Why'),
                  const _NavLink('How it works'),
                  const _NavLink('Features'),
                  const SizedBox(width: 6),
                ],
                const _ThemeToggle(),
                const SizedBox(width: 10),
                _PillButton(
                  label: 'Get the app',
                  background: p.accent,
                  foreground: const Color(0xFF04181A),
                  glow: true,
                  url: _androidUrl,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final double size;
  final bool label;
  const _Logo({required this.size, this.label = false});
  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.29),
            boxShadow: [
              BoxShadow(
                color: p.glow,
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.29),
            child: Image.asset(
              'assets/logo.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (label) ...[
          const SizedBox(width: 12),
          Text(
            'Tornado Gallery',
            style: grotesk(
              size: 18,
              weight: FontWeight.w700,
              color: p.text,
              spacing: -0.18,
            ),
          ),
        ],
      ],
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  const _NavLink(this.label);
  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: _h ? p.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          widget.label,
          style: plex(
            size: 14.5,
            weight: FontWeight.w500,
            color: _h ? p.text : p.muted,
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatefulWidget {
  const _ThemeToggle();
  @override
  State<_ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<_ThemeToggle> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final scope = SiteScope.of(context);
    final p = scope.palette;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: scope.toggleTheme,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _h ? p.surface2 : p.surface,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            p.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            size: 18,
            color: p.text,
          ),
        ),
      ),
    );
  }
}

/// ----------------------------------------------------------------------------
/// Reusable buttons
/// ----------------------------------------------------------------------------
class _PillButton extends StatefulWidget {
  final String label;
  final Color background;
  final Color foreground;
  final bool glow;
  final Color? border;
  final String? url;
  const _PillButton({
    required this.label,
    required this.background,
    required this.foreground,
    this.glow = false,
    this.border,
    this.url,
  });
  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.url == null ? null : () => _openUrl(widget.url!),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _h ? -1 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: widget.background,
            borderRadius: BorderRadius.circular(10),
            border: widget.border != null
                ? Border.all(color: widget.border!)
                : null,
            boxShadow: widget.glow
                ? [
                    BoxShadow(
                      color: p.glow,
                      blurRadius: 22,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: plex(
              size: 14.5,
              weight: FontWeight.w600,
              color: widget.foreground,
            ),
          ),
        ),
      ),
    );
  }
}

/// Store download card button (icon + two lines).
class _StoreButton extends StatefulWidget {
  final String top;
  final String bottom;
  final Color iconBg;
  final IconData icon;
  final String url;
  const _StoreButton({
    required this.top,
    required this.bottom,
    required this.iconBg,
    required this.icon,
    required this.url,
  });
  @override
  State<_StoreButton> createState() => _StoreButtonState();
}

class _StoreButtonState extends State<_StoreButton> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: () => _openUrl(widget.url),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _h ? -3 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
            color: p.surface2,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _h ? p.glow : p.shadow,
                blurRadius: _h ? 36 : 26,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: const Color(0xFF04181A),
                ),
              ),
              const SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.top, style: mono(size: 11, color: p.muted)),
                  Text(
                    widget.bottom,
                    style: grotesk(
                      size: 16,
                      weight: FontWeight.w600,
                      color: p.text,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------------------------------------------------------------
/// HERO
/// ----------------------------------------------------------------------------
class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    final narrow = _isNarrow(context);

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Badge(),
        const SizedBox(height: 24),
        // Gradient headline.
        DefaultTextStyle.merge(
          style: grotesk(
            size: narrow ? 40 : 60,
            weight: FontWeight.w700,
            color: p.text,
            height: 1.02,
            spacing: -1.4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your photos,'),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: [p.accent, p.amber],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(b),
                    child: const Text(
                      'scrambled',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const Text(' beyond'),
                ],
              ),
              const Text('recognition.'),
            ],
          ),
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Tornado Gallery visually encrypts your images into harmless-looking '
            'glitch. Only your password brings them back — pixel-perfect.',
            style: plex(size: 18.5, color: p.muted, height: 1.6),
          ),
        ),
        const SizedBox(height: 34),
        const Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _StoreButton(
              top: 'Download for',
              bottom: 'iOS · App Store',
              iconBg: Color(0xFF36D6D0),
              icon: Icons.phone_iphone_rounded,
              url: _iosUrl,
            ),
            _StoreButton(
              top: 'Download for',
              bottom: 'Android · Google Play',
              iconBg: Color(0xFFF5B833),
              icon: Icons.android_rounded,
              url: _androidUrl,
            ),
          ],
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            Text('✦ no uploads', style: mono(size: 12.5, color: p.muted)),
            Text('✦ no metadata', style: mono(size: 12.5, color: p.muted)),
            Text('✦ lossless', style: mono(size: 12.5, color: p.muted)),
          ],
        ),
      ],
    );

    const visual = _HeroVisual();

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.76, -0.84),
          radius: 0.9,
          colors: [p.glow, Colors.transparent],
        ),
      ),
      child: _Shell(
        padding: const EdgeInsets.fromLTRB(24, 84, 24, 90),
        child: narrow
            ? Column(children: [left, const SizedBox(height: 48), visual])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 105, child: left),
                  const SizedBox(width: 48),
                  const Expanded(flex: 95, child: visual),
                ],
              ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge();
  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: p.accent,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: p.accent, blurRadius: 12)],
            ),
          ),
          const SizedBox(width: 9),
          Text(
            'open source · 100% local · no account',
            style: mono(size: 12.5, color: p.muted, spacing: 0.25),
          ),
        ],
      ),
    );
  }
}

class _HeroVisual extends StatefulWidget {
  const _HeroVisual();
  @override
  State<_HeroVisual> createState() => _HeroVisualState();
}

class _HeroVisualState extends State<_HeroVisual>
    with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat(reverse: true);
  late final AnimationController _beam = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat(reverse: true);
  final _tiles = _makeTiles(16 * 22);

  @override
  void dispose() {
    _float.dispose();
    _beam.dispose();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    return SizedBox(
      height: 480,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _FloatingPixel(
            top: 0.06 * 480,
            left: 6,
            size: 16,
            color: p.amber,
            period: 6,
          ),
          _FloatingPixel(
            top: 0.18 * 480,
            right: 12,
            size: 11,
            color: p.accent,
            period: 7,
          ),
          _FloatingPixel(
            bottom: 0.10 * 480,
            left: 24,
            size: 13,
            color: p.accent,
            period: 8,
          ),
          _FloatingPixel(
            bottom: 0.20 * 480,
            right: 26,
            size: 9,
            color: p.amber,
            period: 6,
          ),
          // Phone card.
          AnimatedBuilder(
            animation: _float,
            builder: (context, child) {
              final dy = math.sin(_float.value * math.pi) * -16;
              return Transform.translate(
                offset: Offset(0, dy),
                child: Transform.rotate(angle: 3 * math.pi / 180, child: child),
              );
            },
            child: _phoneCard(p),
          ),
        ],
      ),
    );
  }

  Widget _phoneCard(Palette p) {
    return Container(
      width: 312,
      height: 430,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 80,
            offset: const Offset(0, 30),
          ),
          BoxShadow(color: p.glow, blurRadius: 60),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Screen.
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: const Color(0xFF04141A),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _GlitchGrid(columns: 16, tiles: _tiles),
                    ),
                    // Scan beam.
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _beam,
                        builder: (context, _) {
                          return LayoutBuilder(
                            builder: (context, c) {
                              final h = c.maxHeight;
                              final beamH = h * 0.34;
                              final y =
                                  -beamH + _beam.value * (h + beamH * 2);
                              return Stack(
                                children: [
                                  Positioned(
                                    top: y,
                                    left: 0,
                                    right: 0,
                                    height: beamH,
                                    child: IgnorePointer(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              p.accent.withValues(alpha: 0.22),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                    // Caption.
                    const Positioned(
                      left: 14,
                      bottom: 14,
                      child: _CaptionChip('ENCRYPTED · 0 metadata'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bobbing corner logo.
          Positioned(
            top: -26,
            right: -22,
            child: AnimatedBuilder(
              animation: _bob,
              builder: (context, child) {
                final v = _bob.value;
                return Transform.translate(
                  offset: Offset(0, math.sin(v * math.pi) * -10),
                  child: Transform.rotate(
                    angle: (-3 + v * 6) * math.pi / 180,
                    child: child,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: p.shadow,
                      blurRadius: 40,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(color: p.glow, blurRadius: 36),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptionChip extends StatelessWidget {
  final String text;
  const _CaptionChip(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xA8041A1A),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0x4D36D6D0)),
      ),
      child: Text(text, style: mono(size: 11, color: const Color(0xFFBFEAE8))),
    );
  }
}

class _FloatingPixel extends StatefulWidget {
  final double? top, left, right, bottom;
  final double size;
  final Color color;
  final double period;
  const _FloatingPixel({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    required this.period,
  });
  @override
  State<_FloatingPixel> createState() => _FloatingPixelState();
}

class _FloatingPixelState extends State<_FloatingPixel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (widget.period * 1000).round()),
  )..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: widget.left,
      right: widget.right,
      bottom: widget.bottom,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = math.sin(_c.value * math.pi);
          return Transform.translate(
            offset: Offset(v * 6, v * -14),
            child: Transform.rotate(
              angle: v * 12 * math.pi / 180,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [BoxShadow(color: widget.color, blurRadius: 18)],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ----------------------------------------------------------------------------
/// Section heading (kicker + title + optional body).
/// ----------------------------------------------------------------------------
class _SectionHead extends StatelessWidget {
  final String kicker, title;
  final String? body;
  const _SectionHead({required this.kicker, required this.title, this.body});
  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    final narrow = _isNarrow(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kicker, style: mono(size: 13, color: p.accent, spacing: 0.78)),
          const SizedBox(height: 14),
          Text(
            title,
            style: grotesk(
              size: narrow ? 28 : 42,
              weight: FontWeight.w700,
              color: p.text,
              height: 1.08,
              spacing: -0.8,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 14),
            Text(body!, style: plex(size: 17, color: p.muted, height: 1.6)),
          ],
        ],
      ),
    );
  }
}

/// Responsive equal-width card grid.
class _CardGrid extends StatelessWidget {
  final List<Widget> children;
  const _CardGrid({required this.children});
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w < 640 ? 1 : (w < 980 ? 2 : 3);
    const gap = 20.0;
    return LayoutBuilder(
      builder: (context, c) {
        final tileW = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((e) => SizedBox(width: tileW, child: e))
              .toList(),
        );
      },
    );
  }
}

/// ----------------------------------------------------------------------------
/// PROBLEM
/// ----------------------------------------------------------------------------
class _ProblemSection extends StatelessWidget {
  const _ProblemSection();
  static const _items = [
    (
      'The over-the-shoulder moment',
      'Handing your unlocked phone to a friend shouldn’t mean exposing every private photo in your camera roll.',
    ),
    (
      'Cloud scanners',
      'Photos you back up get quietly scanned and profiled by the big companies that host them.',
    ),
    (
      'Hidden metadata',
      'Every image carries where, when and on what device it was taken — long after you’ve forgotten.',
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Reveal(
            child: _SectionHead(
              kicker: '// THE PROBLEM',
              title: 'Your gallery is more exposed than you think.',
            ),
          ),
          const SizedBox(height: 46),
          _CardGrid(
            children: _items
                .map(
                  (e) => Reveal(
                    child: _ProblemCard(title: e.$1, body: e.$2),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  final String title, body;
  const _ProblemCard({required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.surface2,
              border: Border.all(color: p.border),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: p.amber,
                    boxShadow: [BoxShadow(color: p.amber, blurRadius: 14)],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: grotesk(size: 19, weight: FontWeight.w600, color: p.text),
          ),
          const SizedBox(height: 10),
          Text(body, style: plex(size: 15.5, color: p.muted, height: 1.6)),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------------------
/// HOW IT WORKS
/// ----------------------------------------------------------------------------
class _HowSection extends StatelessWidget {
  const _HowSection();
  static const _steps = [
    (
      '1',
      'Select your photos',
      'Pick one or many images straight from your gallery.',
    ),
    (
      '2',
      'Set a password',
      'Your password is the only key. It is never stored or sent anywhere.',
    ),
    (
      '3',
      'Get glitched images',
      'The app encrypts byte by byte and outputs files that look like noise — with zero metadata.',
    ),
    (
      '4',
      'Store, share, restore',
      'Keep them anywhere or send to a friend. The same password rebuilds the original, losslessly.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final narrow = _isNarrow(context);
    final steps = Column(
      children: [
        for (final s in _steps) ...[
          _StepRow(n: s.$1, title: s.$2, body: s.$3),
          if (s != _steps.last) const SizedBox(height: 14),
        ],
      ],
    );
    const demo = _EncryptDemo();

    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Reveal(
            child: _SectionHead(
              kicker: '// HOW IT WORKS',
              title: 'Encrypt to glitch. Decrypt to perfect.',
              body:
                  'A password drives a byte-by-byte cipher across the image. The result is a file that '
                  'looks like noise — until the same password rebuilds the original, pixel for pixel.',
            ),
          ),
          const SizedBox(height: 46),
          if (narrow)
            Column(
              children: [
                Reveal(child: steps),
                const SizedBox(height: 40),
                const Reveal(child: demo),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 100, child: Reveal(child: steps)),
                const SizedBox(width: 40),
                const Expanded(flex: 115, child: Reveal(child: demo)),
              ],
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String n, title, body;
  const _StepRow({required this.n, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: p.glow, blurRadius: 18)],
            ),
            child: Center(
              child: Text(
                n,
                style: grotesk(
                  size: 15,
                  weight: FontWeight.w700,
                  color: const Color(0xFF04181A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: grotesk(
                    size: 17,
                    weight: FontWeight.w600,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: plex(size: 14.5, color: p.muted, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EncryptDemo extends StatefulWidget {
  const _EncryptDemo();
  @override
  State<_EncryptDemo> createState() => _EncryptDemoState();
}

class _EncryptDemoState extends State<_EncryptDemo>
    with SingleTickerProviderStateMixin {
  bool _encrypted = true;
  final _tiles = _makeTiles(20 * 14);
  late final AnimationController _beam = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _beam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    final caption = _encrypted
        ? '> applied password · output is pure glitch, no metadata, safe to store anywhere.'
        : '> same password applied · original rebuilt byte-for-byte, no quality loss.';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.card,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 70,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs.
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border.all(color: p.border),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _tab(
                    'Encrypt →',
                    _encrypted,
                    () => setState(() => _encrypted = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _tab(
                    '← Decrypt',
                    !_encrypted,
                    () => setState(() => _encrypted = false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Image area.
          AspectRatio(
            aspectRatio: 20 / 14,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: const Color(0xFF04141A),
                child: Stack(
                  children: [
                    // Original photo (gradient stand-in).
                    AnimatedOpacity(
                      opacity: _encrypted ? 0 : 1,
                      duration: const Duration(milliseconds: 600),
                      child: const _OriginalPhoto(),
                    ),
                    // Encrypted glitch.
                    AnimatedOpacity(
                      opacity: _encrypted ? 1 : 0,
                      duration: const Duration(milliseconds: 600),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _GlitchGrid(columns: 20, tiles: _tiles),
                          ),
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _beam,
                              builder: (context, _) {
                                return LayoutBuilder(
                                  builder: (context, c) {
                                    final h = c.maxHeight;
                                    final beamH = h * 0.30;
                                    final y =
                                        -beamH + _beam.value * (h + beamH * 2);
                                    return Stack(
                                      children: [
                                        Positioned(
                                          top: y,
                                          left: 0,
                                          right: 0,
                                          height: beamH,
                                          child: IgnorePointer(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    p.amber.withValues(
                                                      alpha: 0.18,
                                                    ),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge.
                    Positioned(
                      right: 14,
                      top: 14,
                      child: _CaptionChip(
                        _encrypted ? 'ENCRYPTED' : 'RESTORED',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(caption, style: mono(size: 12.5, color: p.muted, height: 1.5)),
        ],
      ),
    );
  }

  Widget _tab(String label, bool on, VoidCallback onTap) {
    final p = SiteScope.of(context).palette;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: on ? p.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: p.glow,
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: grotesk(
                size: 14.5,
                weight: FontWeight.w600,
                color: on ? const Color(0xFF04181A) : p.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OriginalPhoto extends StatelessWidget {
  const _OriginalPhoto();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: Image(
            image: AssetImage('assets/original.webp'),
            fit: BoxFit.cover,
          ),
        ),
        // Sun glow.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.48, -0.4),
                radius: 0.5,
                colors: [Color(0xD9FFF0C8), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          bottom: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xB3FFFFFF),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              'original.jpg · your photo',
              style: mono(size: 11, color: const Color(0xFF06202A)),
            ),
          ),
        ),
      ],
    );
  }
}

/// ----------------------------------------------------------------------------
/// FEATURES
/// ----------------------------------------------------------------------------
enum _IconShape {
  diamondFill,
  ringAmber,
  squareAccent,
  circleAmber,
  diamondRing,
  barAmber,
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();
  static const _items = <(String, String, _IconShape)>[
    (
      'Visual encryption',
      'Encrypted images render as harmless glitch — nothing recognizable in your gallery or anyone’s scanner.',
      _IconShape.diamondFill,
    ),
    (
      'Byte-level cipher',
      'Your password drives the cipher across every byte of the image. Not a filter — real encryption.',
      _IconShape.ringAmber,
    ),
    (
      'Zero metadata',
      'Output carries no EXIF, no location, no device fingerprint. Clean files, safe to store anywhere.',
      _IconShape.squareAccent,
    ),
    (
      '100% local',
      'All processing happens on-device. No servers, no accounts, no uploads — ever.',
      _IconShape.circleAmber,
    ),
    (
      'Lossless recovery',
      'The same password regenerates the exact original — no compression, no quality loss.',
      _IconShape.diamondRing,
    ),
    (
      'Open source',
      'The code is open and auditable. Free for personal use — verify it, then trust it.',
      _IconShape.barAmber,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Reveal(
            child: _SectionHead(
              kicker: '// WHAT YOU GET',
              title: 'Real encryption. Zero compromise.',
            ),
          ),
          const SizedBox(height: 46),
          _CardGrid(
            children: _items
                .map(
                  (e) => Reveal(
                    child: _FeatureCard(title: e.$1, body: e.$2, shape: e.$3),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final String title, body;
  final _IconShape shape;
  const _FeatureCard({
    required this.title,
    required this.body,
    required this.shape,
  });
  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: Matrix4.translationValues(0, _h ? -4 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: _h ? p.accent : p.border),
          borderRadius: BorderRadius.circular(20),
          boxShadow: _h
              ? [
                  BoxShadow(
                    color: p.shadow,
                    blurRadius: 44,
                    offset: const Offset(0, 18),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: p.surface2,
                border: Border.all(color: p.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: _icon(p)),
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              style: grotesk(
                size: 18.5,
                weight: FontWeight.w600,
                color: p.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.body,
              style: plex(size: 15, color: p.muted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon(Palette p) {
    BoxShadow gl(Color c) => BoxShadow(color: c, blurRadius: 14);
    switch (widget.shape) {
      case _IconShape.diamondFill:
        return Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: p.accent,
              boxShadow: [gl(p.accent)],
            ),
          ),
        );
      case _IconShape.ringAmber:
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: p.amber, width: 3),
            boxShadow: [gl(p.amber)],
          ),
        );
      case _IconShape.squareAccent:
        return Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: p.accent,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [gl(p.accent)],
          ),
        );
      case _IconShape.circleAmber:
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: p.amber,
            shape: BoxShape.circle,
            boxShadow: [gl(p.amber)],
          ),
        );
      case _IconShape.diamondRing:
        return Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              border: Border.all(color: p.accent, width: 3),
              boxShadow: [gl(p.accent)],
            ),
          ),
        );
      case _IconShape.barAmber:
        return Container(
          width: 15,
          height: 6,
          decoration: BoxDecoration(
            color: p.amber,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [gl(p.amber)],
          ),
        );
    }
  }
}

/// ----------------------------------------------------------------------------
/// PRIVACY BAND
/// ----------------------------------------------------------------------------
class _PrivacyBand extends StatelessWidget {
  const _PrivacyBand();
  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    final narrow = _isNarrow(context);

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nothing leaves your phone. Nothing to trust but the code.',
          style: grotesk(
            size: narrow ? 26 : 38,
            weight: FontWeight.w700,
            color: p.text,
            height: 1.1,
            spacing: -0.76,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Tornado Gallery runs entirely on-device and is fully open source. No servers see your images, '
            'no account is required, and anyone can read exactly how the encryption works.',
            style: plex(size: 16.5, color: p.muted, height: 1.6),
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ['100% local', 'open source', 'no account', 'no metadata']
              .map(
                (t) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface2,
                    border: Border.all(color: p.border),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(t, style: mono(size: 12.5, color: p.text)),
                ),
              )
              .toList(),
        ),
      ],
    );

    const code = _CodePanel();

    return _Shell(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 70),
      child: Reveal(
        child: Container(
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 54),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.bg2, p.surface],
            ),
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: p.shadow,
                blurRadius: 70,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [p.glow, Colors.transparent],
                      stops: const [0, 0.7],
                    ),
                  ),
                ),
              ),
              narrow
                  ? Column(children: [text, const SizedBox(height: 32), code])
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 110, child: text),
                        const SizedBox(width: 40),
                        const Expanded(flex: 90, child: code),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodePanel extends StatelessWidget {
  const _CodePanel();
  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    const grey = Color(0xFF5A7D82);
    const cyan = Color(0xFF36D6D0);
    const amber = Color(0xFFF5B833);
    const pale = Color(0xFFBFEAE8);
    TextStyle base(Color c) => mono(size: 13, color: c, height: 1.7);

    Widget line(List<TextSpan> spans) =>
        Text.rich(TextSpan(children: spans), style: base(p.muted));

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF04141A),
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cyan.withValues(alpha: 0.06),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('// per-byte cipher', style: base(grey)),
          line([
            TextSpan(text: 'input', style: base(cyan)),
            const TextSpan(text: '  = photo.bytes'),
            TextSpan(text: '[]', style: base(grey)),
          ]),
          line([
            TextSpan(text: 'key', style: base(cyan)),
            const TextSpan(text: '    = sha('),
            TextSpan(text: '"your password"', style: base(amber)),
            const TextSpan(text: ')'),
          ]),
          line([
            TextSpan(text: 'output', style: base(cyan)),
            const TextSpan(text: ' = input '),
            TextSpan(text: '⊕', style: base(amber)),
            const TextSpan(text: ' stream(key)'),
          ]),
          const SizedBox(height: 8),
          Text('// → looks like noise, 0 metadata', style: base(grey)),
          const SizedBox(height: 8),
          Text('decrypt(output, key) === photo ✓', style: base(pale)),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------------------------------
/// DOWNLOAD CTA
/// ----------------------------------------------------------------------------
class _DownloadCta extends StatelessWidget {
  const _DownloadCta();
  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    final narrow = _isNarrow(context);
    return _Shell(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 90),
      child: Reveal(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(28),
            gradient: RadialGradient(
              center: const Alignment(0, -1.4),
              radius: 1.0,
              colors: [p.glow, Colors.transparent],
              stops: const [0, 0.6],
            ),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: p.glow,
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Hide your photos in plain sight.',
                textAlign: TextAlign.center,
                style: grotesk(
                  size: narrow ? 30 : 50,
                  weight: FontWeight.w700,
                  color: p.text,
                  height: 1.04,
                  spacing: -1.25,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'Free for personal use. Open source. Available now on iOS and Android.',
                  textAlign: TextAlign.center,
                  style: plex(size: 18, color: p.muted, height: 1.6),
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  _PillButton(
                    label: 'Download for iOS',
                    background: p.accent,
                    foreground: const Color(0xFF04181A),
                    glow: true,
                    url: _iosUrl,
                  ),
                  _PillButton(
                    label: 'Download for Android',
                    background: p.surface2,
                    foreground: p.text,
                    border: p.border,
                    url: _androidUrl,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------------------------------------------------------------
/// FOOTER
/// ----------------------------------------------------------------------------
class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) {
    final p = SiteScope.of(context).palette;
    final narrow = _isNarrow(context);
    final brand = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Logo(size: 34),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tornado Gallery',
              style: grotesk(size: 15, weight: FontWeight.w700, color: p.text),
            ),
            Text(
              'visual encryption, on-device',
              style: mono(size: 11.5, color: p.muted),
            ),
          ],
        ),
      ],
    );
    final copy = Text(
      '© 2026 Riccardo Cescon. Free for personal use.\nCommercial use requires the author\'s permission.',
      textAlign: narrow ? TextAlign.left : TextAlign.right,
      style: mono(size: 12, color: p.muted, height: 1.6),
    );
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
            child: narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [brand, const SizedBox(height: 20), copy],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [brand, copy],
                  ),
          ),
        ),
      ),
    );
  }
}
