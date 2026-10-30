# 추가 연습 테스트

기존 `sample` 외에 32개의 입력/예상 출력 쌍을 추가했습니다.
각 `.out`은 해당 입력의 reduction 출력이며 LF 줄바꿈을 사용합니다.
구현 방법이나 우선순위 선언 코드는 포함하지 않습니다.

실제 구현이 있는 WSL 프로젝트의 `tests/`에 `t*.c`, `t*.out`을 복사한 뒤,
그 프로젝트 디렉터리에서 실행하세요. Makefile이나 테스트 검사기를 수정할 필요는 없습니다.

```sh
make test CASE=t03_global_decls
make test CASE=t09_binary_precedence
make test
```

| 테스트 이름 (`CASE`) | 확인하는 내용 |
| --- | --- |
| `t01_empty` | 0바이트 빈 입력 |
| `t02_comments_only` | 중첩 주석만 있는 입력 |
| `t03_global_decls` | 전역 변수, 포인터, 배열 선언 |
| `t04_structs` | 빈 구조체, 멤버 선언, 구조체 참조 및 변수 선언 |
| `t05_functions` | 빈 함수, 여러 함수, 포인터 반환형 |
| `t06_parameters` | 여러 매개변수, 포인터·배열·구조체 매개변수 |
| `t07_local_blocks` | 지역 선언, 중첩 블록, 빈 블록, 빈 문장 |
| `t08_literals` | 정수·문자·문자열 상수, 지원 이스케이프, NULL |
| `t09_binary_precedence` | 서로 다른 이항 연산자의 조합 |
| `t10_left_associativity` | 같은 우선순위 이항 연산자의 연속 사용 |
| `t11_assignment` | 연속 대입, 괄호 안 대입, 배열·역참조 대입 |
| `t12_prefix_operators` | 전위 연산자와 중첩 전위 연산 |
| `t13_postfix_operators` | 후위 증가·감소 연산 |
| `t14_prefix_postfix` | 전위·후위·멤버·배열·호출 연산의 조합 |
| `t15_parentheses` | 괄호로 묶은 식과 중첩 괄호 |
| `t16_array_access` | 배열 접근, 인덱스 식, 호출 결과의 배열 접근 |
| `t17_member_access` | 점 및 화살표 멤버 접근, 연속 접근 |
| `t18_function_calls` | 인자 없는 호출, 여러 인자, 중첩 호출 |
| `t19_if_else` | if, if/else, 블록을 사용한 분기 |
| `t20_dangling_else` | 중첩 if/else와 중괄호 |
| `t21_while` | 단일 문장 및 블록 반복, break와 continue |
| `t22_for` | for 반복문과 블록 본문 |
| `t23_for_optional` | for의 세 식에 대한 생략 여부 8가지 조합 |
| `t24_keyword_names` | 키워드와 비슷한 식별자, 대소문자, float 식별자 |
| `t25_comments_between_tokens` | 토큰 사이의 주석과 중첩 주석 |
| `t26_crlf` | CRLF 줄바꿈 입력 |
| `t27_no_final_newline` | 마지막 줄바꿈 없는 입력 |
| `t28_syntax_only` | 의미 검사 없이 구문만 분석하는지 확인 |
| `t29_operator_spellings` | 관계·동등 연산자 등을 포함한 연산자 표기 |
| `t30_whitespace` | 공백·탭·LF·CRLF 혼합 |
| `t31_token_limits` | 4096바이트 식별자·문자열 토큰, 최대 정수 상수 |
| `t32_comment_depth` | 주석 중첩 깊이 256 |

과제에서는 선언 여부, 타입, lvalue, 반복문 문맥을 검사하지 않습니다.
따라서 `t28_syntax_only` 등의 입력에는 일반 C에서 의미 오류가 되는 식이나
문장이 있어도 subC의 주어진 문법에 맞으면 포함되어 있습니다.

`t01_empty.c`는 비어 있는 것이 정상입니다. `t26_crlf.c`의 줄바꿈과
`t27_no_final_newline.c`의 마지막 줄바꿈 여부는 테스트 조건이므로 유지하세요.

추가 테스트 전체는 PDF의 production 71개를 모두 사용합니다.
이는 채점 테스트 전체를 통과한다는 보장은 아닙니다.
