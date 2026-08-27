# 아이뱅크매니저 Flutter 앱

React 프로토타입을 네이티브 Flutter 앱으로 옮긴 프로젝트입니다.

## 실행

```powershell
cd C:\IBM_I_BANK_MANAGER
flutter pub get
flutter run
```

연결된 기기는 `flutter devices`로 확인할 수 있습니다.

### 로그인과 카카오 설정

앱은 로그인/회원가입 화면에서 시작합니다. 발표용 테스트 계정은
`test001@gmail.com`(김은찬)과 `test002@gmail.com`(김민진)이며, 비밀번호 원문은
저장소에 기록하지 않습니다. 일반 이메일 회원가입과 로그인은 Firebase
Authentication을 사용하므로 Firebase 콘솔의 Authentication > Sign-in method에서
이메일/비밀번호 제공자를 활성화해야 합니다.

카카오 로그인은 Kakao Developers에서 앱을 만든 뒤 Android 플랫폼에
`com.ibm.money.ibm_money_app` 패키지와 키 해시를 등록하고, 카카오 로그인 및
동의항목의 닉네임·프로필 사진을 활성화해야 합니다. 발급받은 Native App Key는
Git에 올리지 않고 `android/local.properties`에 다음 한 줄로 추가합니다.

```properties
kakao.nativeAppKey=발급받은_NATIVE_APP_KEY
```

`run_phone.bat`은 이 값을 Android 리다이렉트 스킴과 Dart SDK 초기화 값에 함께
전달합니다. 김은찬의 가져온 소비 데이터는 휴대폰에 유지되고, 김민진의 데이터는
앱 프로세스를 완전히 종료하면 초기화됩니다.

### 실제 Android 휴대폰에서 실행

1. 휴대폰의 개발자 옵션과 USB 디버깅을 켭니다.
2. USB로 PC에 연결하고 휴대폰에 나타나는 디버깅 허용 창을 승인합니다.
3. 휴대폰 실행 스크립트를 실행합니다.

```powershell
cd C:\IBM_I_BANK_MANAGER
.\run_phone.bat
```

휴대폰이 여러 대 연결되어 있다면 `flutter devices`에서 ID를 확인해
`.\run_phone.bat 휴대폰_ID`로 실행합니다. 이 스크립트는 최신 로컬 API 서버를
자동으로 실행하고 USB 포트 전달을 설정하므로
휴대폰이 에뮬레이터 전용 주소 `10.0.2.2`를 사용하지 않고 PC의 검색 서버에 연결됩니다.
개발 중에는 USB 연결과 PC의 검색 서버를 유지해야 합니다.

예전 버전의 `server.mjs`가 8080 포트에서 실행 중이면 `run_phone.bat`이 해당
프로세스를 최신 버전으로 안전하게 교체합니다. 다른 프로그램이 8080 포트를 사용
중일 때는 그 프로그램을 임의로 종료하지 않고 오류를 표시합니다. 휴대폰이 `offline`으로 표시되면
화면 잠금을 해제하고 USB 디버깅 허용 창을 승인하세요. 실행 스크립트도 오프라인
기기에 한 번 자동 재연결을 시도합니다.

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

## 토스뱅크 소비 데이터 가져오기

통계 탭의 `내역 가져오기`에서 토스뱅크 거래내역서 파일을 선택할 수 있습니다.
CSV뿐 아니라 Excel `.xlsx`·`.xls`와 탭으로 구분된 `.txt` 파일을 지원합니다.
비밀번호로 보호된 `.xlsx` 파일을 선택하면 열기 비밀번호를 입력받아
휴대폰 안에서 복호화합니다. 입력한 비밀번호는 저장하지 않습니다.
날짜, 거래내용, 출금금액을 기준으로 이번 달 총지출·거래 횟수·건당 평균·하루
평균·가장 많이 쓴 곳·최근 내역을 계산하며, 거래 후 잔액 열이 있으면 현재 잔액도
함께 반영합니다.

`알림 자동 등록`은 Android 설정에서 사용자가 직접 알림 접근을 허용한 이후의
토스 출금·결제 알림만 저장합니다. 실제 토스 계좌를 연결하거나 인터넷뱅킹
비밀번호를 수집하지 않으며, 가져온 소비 데이터는 해당 휴대폰의 앱 저장소에만
보관됩니다. Android 8.0(API 26) 이상을 지원합니다.

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
- 이메일 로그인·회원가입과 카카오 프로필 로그인
- 알림 목록과 읽음 처리
- 월간 소비 통계와 카테고리 필터
- 토스뱅크 Excel·CSV 거래내역 가져오기와 로컬 저장
- Android 토스 지출 알림 자동 등록
- 구독·고정지출 직접 등록·수정·삭제
- watsonx AI가 월간 소비 합계와 카테고리를 분석하는 `이번 달 한마디`
- watsonx AI로 검색 의도·예산 해석
- 실제 온라인 상품 사진·상품명·가격 검색 및 선택
- 검색 상품을 위시리스트와 저축 목표로 연결
- 실제 결제가 발생하지 않는 데모 결제 흐름
