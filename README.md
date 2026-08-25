# 아이뱅크매니저 Flutter 앱

React 프로토타입을 네이티브 Flutter 앱으로 옮긴 프로젝트입니다.

## 실행

```powershell
cd C:\IBM_I_BANK_MANAGER
flutter pub get
flutter run
```

연결된 기기는 `flutter devices`로 확인할 수 있습니다.

### Android 17 베타 에뮬레이터

Android 17 베타/16 KB 시스템 이미지에서 검은 화면이 나타나면 Device Manager에서
해당 AVD의 Graphics를 Software로 설정하고 Cold Boot한 뒤 다음 파일로 실행하세요.

```powershell
.\run_emulator.bat
```

이 파일은 에뮬레이터에서 Impeller를 끄고 소프트웨어 렌더링과 로컬 상품 검색 서버
주소(`10.0.2.2:8080`)를 적용합니다. 가능하면 Android 15 또는 16 안정 시스템 이미지를
사용하는 것을 권장합니다.

상품 검색은 API 키를 APK에 넣지 않기 위해 별도 서버를 사용합니다. 먼저 [server/README.md](server/README.md)에 따라 watsonx.ai와 Google Shopping 검색 서버를 실행하세요.

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
- 구독·고정지출 직접 등록·수정·삭제
- 소비 피드백
- watsonx AI로 검색 의도·예산 해석
- 실제 온라인 상품 사진·상품명·가격 검색 및 선택
- 검색 상품을 위시리스트와 저축 목표로 연결
- 실제 결제가 발생하지 않는 데모 결제 흐름
