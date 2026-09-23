// ============================================================
// ITMO laboratory report.
// The project description and security measures are documented below.
// For the closest match, compile locally with Times New Roman,
// Calibri and Courier New installed.
// ============================================================

// ---------- EDIT THIS BLOCK ----------
#let subject = "Информационная безопасность"
#let lab-number = "1"
#let lab-title = "Разработка защищенного REST API с интеграцией в CI/CD"
#let author = "Есев Ярослав Леонидович"
#let group = "P3415"
#let city = "Санкт-Петербург"
#let year = "2026"
// -------------------------------------

#set page(
  paper: "a4",
  margin: (
    top: 2cm,
    bottom: 2cm,
    left: 3cm,
    right: 1.5cm,
  ),
)

#set text(
  font: "Times New Roman",
  size: 14pt,
)

#set par(
  justify: true,
  first-line-indent: 0pt,
  spacing: 8pt,
)

// Headings in the source are Times New Roman, 16 pt, bold.
#show heading.where(level: 1): it => block(
  above: 12pt,
  below: 8pt,
  breakable: false,
)[
  #text(size: 16pt, weight: "bold")[#it.body]
]

// Plain blue underlined web link, matching Word/PDF hyperlink styling.
#let weburl(url) = link(url)[
  #text(fill: rgb("#0563C1"))[
    #underline[#url]
  ]
]

// One-cell bordered code block used for JSON examples.
#show raw: set text(font: "Courier New", size: 12pt)
#let codebox(code) = block(
  width: 100%,
  inset: (left: 6pt, right: 6pt, top: 4pt, bottom: 4pt),
  stroke: 0.5pt + black,
  breakable: false,
)[
  #raw(code, block: true)
]

// ---------- TITLE PAGE ----------
#align(center)[
  Федеральное государственное автономное

  образовательное учреждение высшего образования

  «Национальный исследовательский университет ИТМО»
]

#v(3.0cm)

#align(center)[
  #text(weight: "bold")[#subject]

  #text(weight: "bold")[Лабораторная работа №#lab-number]

  #text(weight: "bold")["#lab-title"]
]

#v(6.0cm)

#align(right)[
  Выполнил:

  #author

  Группа: #group
]

#v(6.6cm)

#align(center)[
  #city,

  #year
]

#pagebreak()

// ---------- TABLE OF CONTENTS ----------
#text(weight: "bold")[Оглавление]
#v(3pt)

#block[
  #set text(font: "Calibri", size: 12pt, weight: "bold", style: "italic")
  #set par(spacing: 6pt)
  #outline(title: none, depth: 1)
]

#v(28pt)

= Инициализация проекта

Для данного проекта был создан репозиторий Git и был связан с репозиторием на GitHub. \
Ссылка на репозиторий: #weburl("https://github.com/yaroslavesev/info_sec_lab1")

= Описание проекта

В данной работе реализовано REST API приложение с аутентификацией пользователей при помощи JWT-токена. Аутентифицированный пользователь может просматривать список постов и создавать новые посты от своего имени.

Приложение написано на Java 17 с использованием Spring Boot, Spring Web MVC, Spring Security и Spring Data JPA. Для хранения данных используется H2 в режиме in-memory. Схема базы данных создаётся при запуске приложения и удаляется после его остановки. Для сборки и запуска проверок используется Maven.

= Список эндпоинтов

API доступен по адресу `http://localhost:8080`. При запуске автоматически создаётся пользователь `admin` с паролем `local-demo-password`. Для защищённых эндпоинтов используется заголовок `Authorization: Bearer <JWT>`.

- POST /auth/login - вход

Формат запроса:

#codebox("{\n  \"username\": \"admin\",\n  \"password\": \"local-demo-password\"\n}")

Формат ответа при успешной аутентификации (`200 OK`):

#codebox("{\n  \"token\": \"<JWT>\",\n  \"tokenType\": \"Bearer\"\n}")

При неверных учётных данных возвращается `401 Unauthorized`.

- GET /api/data - получение списка постов

Формат ответа (`200 OK`):

#codebox("[\n  {\n    \"id\": 1,\n    \"title\": \"Security checklist\",\n    \"body\": \"Use JWT, bcrypt and parameterized queries.\",\n    \"author\": \"admin\"\n  }\n]")

Эндпоинт требует действительный JWT. Без токена или с некорректным токеном возвращается `401 Unauthorized`.

- POST /api/posts - создание поста

Формат запроса:

#codebox("{\n  \"title\": \"New post\",\n  \"body\": \"Secure API example\"\n}")

Формат ответа (`201 Created`):

#codebox("{\n  \"id\": 3,\n  \"title\": \"New post\",\n  \"body\": \"Secure API example\",\n  \"author\": \"admin\"\n}")

Автор определяется по JWT. Заголовок поста ограничен 120 символами, тело ограничено 1000 символами. Поля запроса проверяются аннотациями `@NotBlank` и `@Size`.

#pagebreak()

= Защита от SQL-инъекций

Защита от SQL-инъекций обеспечивается использованием Spring Data JPA поверх Hibernate. Все обращения к H2 выполняются через `AppUserRepository` и `PostRepository`, которые наследуют `JpaRepository`. Метод `findByUsername(request.username())` передаёт имя пользователя как параметр запроса, а создание поста выполняется через `postRepository.save(...)`.

В проекте нет SQL-запросов, собранных конкатенацией строк с пользовательским вводом. Значения `username`, `title` и `body` передаются как данные и не могут изменить структуру SQL-запроса. Дополнительно действуют ограничения модели: имя пользователя уникально и ограничено 64 символами, заголовок поста ограничен 120 символами, а тело поста - 1000 символами.

= Защита от XSS-атак

Приложение является REST API и возвращает данные в формате JSON. Перед формированием ответа `PostController.toResponse(...)` вызывает `HtmlUtils.htmlEscape(...)` для заголовка, текста поста и имени автора. Поэтому строка `<script>alert(1)</script>` возвращается как `&lt;script&gt;alert(1)&lt;/script&gt;` и не интерпретируется как HTML при последующем отображении.

Экранирование применяется как при `GET /api/data`, так и в ответе на `POST /api/posts`. Такой сценарий проверяется тестом `createdPostIsEscapedInApiResponse`.

= Реализация аутентификации пользователя

В работе используется JWT access-токен. Он необходим для доступа к защищённым эндпоинтам. Токен подписывается алгоритмом HS256 секретным ключом и действует 3600 секунд. Секрет читается из настройки `APP_JWT_SECRET` и не должен храниться в репозитории.

Пользователь `admin` создаётся компонентом `DataInitializer` при запуске приложения. Пароль перед сохранением преобразуется в BCrypt-хеш с cost factor 12. При выполнении `POST /auth/login` пользователь ищется через `AppUserRepository`, а введённый пароль сравнивается с хешем методом `PasswordEncoder.matches(...)`. Регистрация через API в проекте не предусмотрена.

После успешного входа `JwtService` формирует токен с полями `subject`, `issuer`, `issuedAt`, `expiresAt` и списком ролей. На защищённых эндпоинтах `JwtAuthenticationFilter` проверяет заголовок `Authorization: Bearer <токен>`, подпись и срок действия токена. После успешной проверки имя пользователя и роли записываются в `SecurityContext`. Фильтр не загружает пользователя из БД на каждом запросе.

В базе данных хранятся только BCrypt-хэши паролей, исходные пароли не сохраняются. `SecurityConfig` разрешает без аутентификации только `/auth/login` и `/error`, остальные запросы требуют действительный JWT. Сессии отключены через `SessionCreationPolicy.STATELESS`, а консоль H2 отключена.

Входные DTO проверяются Bean Validation с помощью `@NotBlank` и `@Size`. Тесты проверяют успешную аутентификацию, отказ без токена, отказ с некорректным токеном, неверный пароль и экранирование XSS.

#pagebreak()

#heading(level: 1, outlined: false)[Полученные отчеты по SAST/SCA из Actions]

SAST (SpotBugs):

#image("sast_screen.png", width: 14.17cm)

SCA (OWASP Dependency-Check):

#image("assets/sca_screen.png", width: 16.50cm)

Ссылка на последний запуск pipeline в репозитории: \
#weburl("https://github.com/yaroslavesev/info_sec_lab1/actions/runs/35867872759")
