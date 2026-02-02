# 📱 MyFeed

> 알고리즘 없이, 내가 선택한 콘텐츠만 시간순으로

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

## 🎯 소개

MyFeed는 SNS 알고리즘에 지친 당신을 위한 개인 피드 큐레이션 앱입니다.

- ✅ **내가 선택한 소스만** - RSS 피드를 직접 구독
- ✅ **시간순 정렬** - 알고리즘 없이 최신순으로
- ✅ **키워드 필터링** - 보기 싫은 주제 차단
- ✅ **북마크** - 나중에 읽기 저장
- ✅ **일간 브리핑** - 텔레그램으로 아침 요약 (예정)

## 📸 스크린샷

> *Coming soon...*

## 🚀 시작하기

### 요구사항

- Flutter 3.x 이상
- Dart 3.x 이상
- (선택) Supabase 프로젝트

### 설치

```bash
# 저장소 클론
git clone https://github.com/yourusername/myfeed.git
cd myfeed

# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

### Supabase 설정 (선택)

1. [Supabase](https://supabase.com)에서 새 프로젝트 생성
2. `database/schema.sql` 실행
3. `lib/config/supabase_config.dart` 수정:

```dart
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_ANON_KEY';
}
```

## 📂 프로젝트 구조

```
lib/
├── config/           # 설정 파일
├── models/           # 데이터 모델
│   ├── feed_source.dart
│   ├── feed_item.dart
│   ├── bookmark.dart
│   └── filter.dart
├── providers/        # 상태 관리 (Provider)
│   ├── feed_provider.dart
│   ├── bookmark_provider.dart
│   └── filter_provider.dart
├── services/         # 비즈니스 로직
│   ├── feed_service.dart
│   └── storage_service.dart
├── screens/          # UI 화면
│   ├── main_screen.dart
│   ├── feed_screen.dart
│   ├── sources_screen.dart
│   ├── bookmarks_screen.dart
│   └── settings_screen.dart
├── widgets/          # 재사용 위젯
│   ├── feed_card.dart
│   ├── source_filter_chip.dart
│   ├── add_feed_dialog.dart
│   └── add_filter_dialog.dart
├── theme/            # 테마 설정
│   └── app_theme.dart
└── main.dart         # 앱 진입점
```

## ✨ 주요 기능

### 1. RSS 피드 구독
- RSS/Atom 피드 URL 추가
- 피드 유효성 자동 검증
- 카테고리별 분류
- 인기 피드 추천

### 2. 통합 피드
- 모든 소스를 시간순으로 통합
- 소스별 필터링
- 읽음/안읽음 표시
- Pull-to-refresh

### 3. 키워드 필터링
- 키워드, 소스, 작성자별 차단
- 숨기기 / 흐리게 표시 옵션

### 4. 북마크
- 원클릭 저장
- 태그 분류
- 메모 추가

## 🛠 기술 스택

| 분류 | 기술 |
|------|------|
| 프레임워크 | Flutter 3.x |
| 상태 관리 | Provider |
| 로컬 저장 | SharedPreferences |
| 백엔드 (선택) | Supabase |
| RSS 파싱 | webfeed_plus |
| HTTP | http 패키지 |
| UI | Material Design 3 |

## 📋 로드맵

- [x] MVP - 기본 피드 리더
- [ ] Supabase 클라우드 동기화
- [ ] 뉴스레터 이메일 파싱
- [ ] 텔레그램 일간 브리핑
- [ ] 오프라인 모드
- [ ] 웹 버전

## 🤝 기여하기

1. Fork
2. Feature 브랜치 생성 (`git checkout -b feature/amazing-feature`)
3. 커밋 (`git commit -m '✨ Add amazing feature'`)
4. Push (`git push origin feature/amazing-feature`)
5. Pull Request

## 📄 라이선스

MIT License - 자유롭게 사용하세요!

## 🙏 감사

- [Flutter](https://flutter.dev)
- [Supabase](https://supabase.com)
- [GeekNews](https://news.hada.io) - 추천 피드

---

Made with ❤️ by MyFeed Team
