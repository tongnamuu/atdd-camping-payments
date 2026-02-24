# atdd-camping-payments

## 개요
캠핑 키오스크용 결제 서비스 에뮬레이터.
Spring Boot 3.2 기반 독립 실행형 서비스로, 결제 생성·승인·취소 API를 제공한다.

## 빌드 및 실행

> **주의**: Java 17 필수 (Lombok 애너테이션 프로세서가 Java 25에서 동작하지 않음)

```bash
# 빌드 (Java 17)
JAVA_HOME=/Users/rook/Library/Java/JavaVirtualMachines/temurin-17.0.16/Contents/Home \
  ./gradlew bootJar -x test --no-daemon

# 로컬 실행
JAVA_HOME=... ./gradlew bootRun
# 또는
java -jar build/libs/atdd-payments-0.0.1-SNAPSHOT.jar
```

서버가 **포트 9090**에서 기동된다.

## Docker

```bash
# 이미지 빌드 및 실행
docker build -t atdd-payments .
docker run -p 9090:9090 atdd-payments

# docker compose (테스트 환경 전체)
# atdd-camping-tests/infra/docker-compose.yml 참조
```

## API

### 인증
모든 요청에 Basic Auth 헤더 필요:
```
Authorization: Basic base64(test_sk_dummy:)
```

### 엔드포인트

| 메서드 | 경로 | 설명 |
|--------|------|------|
| `POST` | `/v1/payments` | 결제 생성 |
| `POST` | `/v1/payments/confirm` | 결제 승인 |
| `POST` | `/v1/payments/{paymentKey}/cancel` | 결제 취소 |

### 결제 생성
```json
POST /v1/payments
{ "paymentKey": "pay_xxx", "orderId": "ord_xxx", "amount": 10000 }

// 응답
{ "paymentKey": "pay_xxx", "orderId": "ord_xxx", "status": "INITIATED" }
```

### 결제 승인
```json
POST /v1/payments/confirm
{ "paymentKey": "pay_xxx", "orderId": "ord_xxx", "amount": 10000 }

// 응답
{ "paymentKey": "...", "orderId": "...", "method": "CARD",
  "approvedAt": "...", "totalAmount": 10000, "status": "APPROVED",
  "receipt": { "url": "https://pay.local/receipts/pay_xxx" } }
```

### 결제 취소
```json
POST /v1/payments/{paymentKey}/cancel
{ "cancelReason": "취소 사유", "cancelAmount": 10000 }

// 응답
{ "status": "CANCELED", "canceledAt": "..." }
```

## 설계 특징
- **인메모리 저장소**: DB 없음, 재시작 시 데이터 초기화
- **멱등 처리**: 동일 paymentKey로 중복 요청 시 기존 상태 반환
- **부분 취소 미지원**: cancelAmount는 전체 금액과 동일해야 함
- **상태 흐름**: `INITIATED` → `APPROVED` → `CANCELED`

## 주요 파일
```
src/main/java/com/camping/payments/
  api/PaymentsController.java      # REST 엔드포인트
  api/GlobalExceptionHandler.java  # 에러 응답 형식
  core/Payment.java                # 도메인 모델
  core/PaymentService.java         # 비즈니스 로직
  core/PaymentStatus.java          # 상태 열거형
  infra/BasicAuthFilter.java       # 인증 필터
  infra/InMemoryPaymentRepository.java
```
