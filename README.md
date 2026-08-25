# 아이뱅크매니저 Flutter 앱

React 프로토타입을 네이티브 Flutter 앱으로 옮긴 프로젝트입니다.

## 실행

```powershell
cd C:\IBM_I_BANK_MANAGER
flutter pub get
flutter run
```

연결된 기기는 `flutter devices`로 확인할 수 있습니다.

### 실제 Android 휴대폰에서 실행

1. 휴대폰의 개발자 옵션과 USB 디버깅을 켭니다.
2. USB로 PC에 연결하고 휴대폰에 나타나는 디버깅 허용 창을 승인합니다.
3. 첫 번째 터미널에서 상품 검색 서버를 실행합니다.

```powershell
cd C:\IBM_I_BANK_MANAGER
node --env-file=server\.env server\server.mjs
```

4. 두 번째 터미널에서 휴대폰 실행 스크립트를 실행합니다.

```powershell
cd C:\IBM_I_BANK_MANAGER
.\run_phone.bat
```

휴대폰이 여러 대 연결되어 있다면 `flutter devices`에서 ID를 확인해
`.\run_phone.bat 휴대폰_ID`로 실행합니다. 이 스크립트는 USB 포트 전달을 설정하므로
휴대폰이 에뮬레이터 전용 주소 `10.0.2.2`를 사용하지 않고 PC의 검색 서버에 연결됩니다.
개발 중에는 USB 연결과 PC의 검색 서버를 유지해야 합니다.

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

일반 상품명은 Google Shopping으로 바로 검색하고, 금액·예산이 포함된 자연어는
watsonx AI가 해석합니다. 같은 검색어의 결과는 5분간 캐시되어 재검색이 더 빠릅니다.

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
