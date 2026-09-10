import 'package:flutter/material.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/features/sharing/domain/entities/share_card.dart';

/// O card em si, desenhado em 360×640 lógicos (9:16). Capturado a
/// `pixelRatio: 3` vira uma imagem de 1080×1920, tamanho de Stories.
///
/// Traz a marca da treinadora, não a do app: quem vê o post associa o
/// resultado a ela.
class ShareCardView extends StatelessWidget {
  const ShareCardView({required this.data, super.key});

  static const double width = 360;
  static const double height = 640;

  final ShareCardData data;

  @override
  Widget build(BuildContext context) {
    final brand = data.brandColor ?? AppColors.primary;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(AppColors.background, brand, 0.35)!,
            AppColors.background,
            Color.lerp(AppColors.background, brand, 0.18)!,
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          // Halo do acento atrás do número, dá profundidade sem imagem.
          Positioned(
            top: 150,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brand.withValues(alpha: 0.22),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: brand,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bolt,
                          size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.coachName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(data.icon, size: 40, color: brand),
                const SizedBox(height: 14),
                Text(
                  data.eyebrow.toUpperCase(),
                  style: TextStyle(
                    color: brand,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                Text(
                  data.caption,
                  style: const TextStyle(
                    color: Color(0xFFCFC7DA),
                    fontSize: 16,
                    height: 1.3,
                  ),
                  maxLines: 3,
                ),
                const Spacer(),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.athleteName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (data.coachHandle != null)
                            Text(
                              '@${data.coachHandle}',
                              style: const TextStyle(
                                color: Color(0xFF9C93AC),
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (data.inviteCode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: brand.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: brand.withValues(alpha: 0.55)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'CÓDIGO',
                              style: TextStyle(
                                color: Color(0xFF9C93AC),
                                fontSize: 9,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              data.inviteCode!,
                              style: TextStyle(
                                color: brand,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
