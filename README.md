# 아이뱅크매니저 Flutter 앱

React 프로토타입을 네이티브 Flutter 앱으로 옮긴 프로젝트입니다.

## 실행

```powershell
cd C:\IBM_I_BANK_MANAGER
flutter pub get
flutter run
```

연결된 기기는 `flutter devices`로 확인할 수 있습니다.

## 확인

```powershell
flutter analyze
flutter test
```

## Android APK 만들기

```powershell
flutter build apk --release
```

APK는 `build\app\outputs\flutter-apk\app-release.apk`에 생성됩니다.

## 구현된 기능

- 홈 저축 계획과 목표 진행률
- 노랑·네이비·초록 테마 전환
- 알림 목록과 읽음 처리
- 월간 소비 통계와 카테고리 필터
- 소비 피드백
- 위시 스토어와 목표 상품 변경
- 실제 결제가 발생하지 않는 데모 결제 흐름
