# 아이뱅크매니저 로컬 API 서버

Flutter 앱에 Secret을 넣지 않기 위한 로컬 API 서버입니다.

- watsonx.ai: 자연어 검색어와 최대 예산 해석
- watsonx.ai: 월간 소비 합계와 카테고리를 분석한 `이번 달 한마디` 생성
- SerpApi Google Shopping: 실제 상품명, 사진, 가격, 판매처 조회

## 필요한 값

1. IBM watsonx.ai 프로젝트의 Developer access 화면에서 Project ID, Base URL, 사용 가능한 Model ID 확인
2. IBM Cloud API key 새로 발급
3. SerpApi에서 Google Shopping API key 발급

채팅이나 GitHub에 Secret을 올리지 마세요. `server/.env.example`을 `server/.env`로 복사한 뒤 로컬 값만 입력합니다. `.env`는 Git에서 제외됩니다.

```powershell
Copy-Item server\.env.example server\.env
node --env-file=server\.env server\server.mjs
```

상태 확인:

```powershell
Invoke-RestMethod http://localhost:8080/health
```

Windows 앱 실행:

```powershell
flutter run -d windows --dart-define=PRODUCT_SEARCH_API_URL=http://localhost:8080
```

Android 에뮬레이터는 기본값 `http://10.0.2.2:8080`을 사용합니다. 실제 휴대폰은 PC와 같은 Wi-Fi에 연결한 뒤 `localhost` 대신 PC의 내부 IP를 지정합니다.

USB로 연결한 실제 Android 휴대폰은 프로젝트 루트의 `run_phone.bat`을 사용하면
현재 API 계약을 지원하는 서버 실행과 `adb reverse`가 자동으로 설정됩니다. 오래된
`server.mjs`가 실행 중이면 최신 서버로 교체하므로 별도 서버 터미널을 먼저 열 필요가
없습니다. 이 방법은 Windows 방화벽이나 PC 내부 IP를 따로 설정할 필요가 없습니다.

```powershell
.\run_phone.bat
```

일반 상품명 검색은 SerpApi로 바로 전달해 응답 시간을 줄이고, 금액이나 예산이
포함된 검색어만 watsonx AI로 해석합니다. 동일 검색어는 기본 5분 동안 메모리에
캐시하며 `SEARCH_CACHE_TTL_MS`로 시간을 조정할 수 있습니다.

운영 환경에서는 이 서버를 HTTPS로 배포하고 Secret Manager를 사용하세요.
