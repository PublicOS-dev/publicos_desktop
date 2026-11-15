import 'package:flutter/material.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

enum ChannelSort { newest, top, hot, controversial }

extension ChannelSortLabel on ChannelSort {
  String get label {
    switch (this) {
      case ChannelSort.newest: return 'New';
      case ChannelSort.top: return 'Top';
      case ChannelSort.hot: return 'Hot';
      case ChannelSort.controversial: return 'Controversial';
    }
  }

  String get queryParam {
    switch (this) {
      case ChannelSort.newest: return 'new';
      case ChannelSort.top: return 'top';
      case ChannelSort.hot: return 'hot';
      case ChannelSort.controversial: return 'controversial';
    }
  }
}

class ChannelSortBar extends StatelessWidget {
  final ChannelSort current;
  final ValueChanged<ChannelSort> onChanged;

  const ChannelSortBar({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return SizedBox(
      height: 52,
      child: HorizontalWheel(child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8, top: 8),
        children: ChannelSort.values.map((sort) {
          final isActive = sort == current;
          final fg = isActive ? tokens.starkWhite : tokens.textDim;
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => onChanged(sort),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? tokens.surfaceElevated
                        : Colors.transparent,
                    border: Border.all(
                      color: isActive
                          ? tokens.borderMedium
                          : tokens.borderSubtle,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    sort.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      height: 1.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      )),
    );
  }
}
