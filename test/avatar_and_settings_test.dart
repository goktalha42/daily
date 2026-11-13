import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_games/core/models/user_avatar.dart';
import 'package:daily_games/core/services/user_avatar_provider.dart';
import 'package:daily_games/core/theme/app_colors.dart';
import 'package:daily_games/core/widgets/sketch_decorations.dart';
import 'package:daily_games/features/profile/settings_screen.dart';
import 'package:daily_games/features/profile/widgets/avatar_picker_dialog.dart';
import 'package:daily_games/features/league/league_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserAvatar Model Tests', () {
    test('Varsayılan avatar crown olmalıdır', () {
      expect(UserAvatar.defaultAvatarId, 'crown');
      final def = UserAvatar.getById(null);
      expect(def.id, 'crown');
      expect(def.emoji, '👑');
    });

    test('Tüm avatarlar benzersiz id ve geçerli bilgilere sahip olmalıdır', () {
      final ids = UserAvatar.allAvatars.map((a) => a.id).toSet();
      expect(ids.length, UserAvatar.allAvatars.length);
      expect(UserAvatar.allAvatars.length, 12);

      for (final a in UserAvatar.allAvatars) {
        expect(a.id.isNotEmpty, true);
        expect(a.label.isNotEmpty, true);
        expect(a.emoji.isNotEmpty, true);
      }
    });

    test('getById geçerli ve geçersiz id durumlarını doğru ele alır', () {
      final owl = UserAvatar.getById('owl');
      expect(owl.id, 'owl');
      expect(owl.label, 'Bilge Baykuş');

      final unknown = UserAvatar.getById('non_existent_avatar_id');
      expect(unknown.id, 'crown'); // Varsayılana döner
    });
  });

  group('UserAvatar Provider & Persistence Tests', () {
    test('Avatar değiştirildiğinde state güncellenir ve SharedPreferences a yazılır', () async {
      SharedPreferences.setMockInitialValues({'zuhtu_user_avatar_id': 'brain'});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // İlk yükleme
      final initial = container.read(userAvatarProvider);
      expect(initial, isA<String>());

      // Yeni avatar seçimi
      await container.read(userAvatarProvider.notifier).setAvatar('wizard');
      expect(container.read(userAvatarProvider), 'wizard');

      final model = container.read(currentAvatarModelProvider);
      expect(model.id, 'wizard');
      expect(model.emoji, '🧙‍♂️');
    });
  });

  group('AvatarPickerDialog Widget Tests', () {
    testWidgets('AvatarPickerDialog açılır ve 12 avatarı listeler', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AvatarPickerDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Avatarını Özelleştir'), findsOneWidget);
      expect(find.text('Kral Taç'), findsOneWidget);
      expect(find.text('Bilge Baykuş'), findsOneWidget);
      expect(find.text('ARKA PLAN RENGİ'), findsOneWidget);
      expect(find.text('Kaydet & Kullan'), findsOneWidget);
    });
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets('SettingsScreen başlık ve tüm yapılandırma bölümlerini eksiksiz gösterir', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Ayarlar'), findsOneWidget);
      expect(find.text('GÖRÜNÜM VE TEMA'), findsOneWidget);
      expect(find.text('SES VE DOKUNSAL HİSSİYAT'), findsOneWidget);
      expect(find.text('BİLDİRİMLER VE GÜNLÜK SERİ'), findsOneWidget);
      expect(find.text('İLERLEME YEDEKLEME VE CİHAZ TAŞIMA'), findsOneWidget);
      expect(find.text('Tanıtım Turunu Tekrar İzle'), findsOneWidget);
      expect(find.text('UYGULAMA SÜRÜMÜ VE BİLGİLERİ'), findsOneWidget);
      expect(find.textContaining('Zühtü v1.2.22 (Build 40)'), findsOneWidget);
      expect(find.text('GİZLİLİK VE POLİTİKALAR'), findsNothing);
      expect(find.text('Gizlilik Politikası (Privacy Policy)'), findsNothing);
      expect(find.text('Açık Kaynak & Lisanslar'), findsNothing);
      expect(find.text('VERİ YÖNETİMİ VE HESAP SIFIRLAMA'), findsOneWidget);
      expect(find.text('Tüm Verileri ve Hesabı Sıfırla'), findsOneWidget);
    });

    testWidgets('Verileri sıfırla butonuna basıldığında onay diyaloğu açılır ve vazgeçilebilir', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({'zuhtu_user_nickname': 'TestOyuncu'});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final resetButton = find.text('Tüm Verileri ve Hesabı Sıfırla');
      expect(resetButton, findsOneWidget);
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      expect(find.text('Tüm Verilerini Silmek İstiyor musun?'), findsOneWidget);
      expect(find.text('Vazgeç'), findsOneWidget);
      expect(find.text('Evet, Sıfırla'), findsOneWidget);

      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();

      expect(find.text('Tüm Verilerini Silmek İstiyor musun?'), findsNothing);
    });

    testWidgets('Verileri sıfırla onaylandığında sıfırlama işlemi yürütülür', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({'zuhtu_user_nickname': 'TestOyuncu'});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final resetButton = find.text('Tüm Verileri ve Hesabı Sıfırla');
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      final confirmBtn = find.text('Evet, Sıfırla');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('zuhtu_user_nickname'), isNull);
    });
  });

  group('LeagueScreen Avatar Tests', () {
    testWidgets('LeagueScreen kullanıcının seçtiği avatarı ve arka plan rengini gösterir', (tester) async {
      SharedPreferences.setMockInitialValues({'zuhtu_user_avatar_id': 'owl:cyan'});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LeagueScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Baykuş emojisi ve seçilen turkuaz arka plan rengi lig ekranında gösterilmelidir
      expect(find.text('🦉'), findsWidgets);
      final cards = tester.widgetList<SketchCard>(find.byType(SketchCard));
      expect(
        cards.any(
          (c) => c.backgroundColor == AppColors.highlighterCyan.withAlpha(130),
        ),
        isTrue,
      );
    });
  });
}
