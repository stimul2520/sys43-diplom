# Дипломная работа по профессии «Системный администратор» - Tarkov Viktor

<details>

<summary>Задание</summary>

Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
* [Выполнение работы](#Выполнение-работы)
* [Критерии сдачи](#Критерии-сдачи)
* [Как правильно задавать вопросы дипломному руководителю](#Как-правильно-задавать-вопросы-дипломному-руководителю) 

---------

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.  

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal  - для этого достаточно при создании ВМ указать name=example, hostname=examle !! 

Важно: используйте по-возможности **минимальные конфигурации ВМ**:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая. 

**Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.**

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Виртуальные машины не должны обладать внешним Ip-адресом, те находится во внутренней сети. Доступ к ВМ по ssh через бастион-сервер. Доступ к web-порту ВМ через балансировщик yandex cloud.

Настройка балансировщика:

1. Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

2. Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

3. Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

4. Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh.  Эта вм будет реализовывать концепцию  [bastion host]( https://cloud.yandex.ru/docs/tutorials/routing/bastion) . Синоним "bastion host" - "Jump host". Подключение  ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью  [ProxyCommand](https://docs.ansible.com/ansible/latest/network/user_guide/network_debug_troubleshooting.html#network-delegate-to-vs-proxycommand) . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

Исходящий доступ в интернет для ВМ внутреннего контура через [NAT-шлюз](https://yandex.cloud/ru/docs/vpc/operations/create-nat-gateway).

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

### Дополнительно
Не входит в минимальные требования. 

1. Для Zabbix можно реализовать разделение компонент - frontend, server, database. Frontend отдельной ВМ поместите в публичную подсеть, назначте публичный IP. Server поместите в приватную подсеть, настройте security group на разрешение трафика между frontend и server. Для Database используйте [Yandex Managed Service for PostgreSQL](https://cloud.yandex.com/en-ru/services/managed-postgresql). Разверните кластер из двух нод с автоматическим failover.
2. Вместо конкретных ВМ, которые входят в target group, можно создать [Instance Group](https://cloud.yandex.com/en/docs/compute/concepts/instance-groups/), для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
3. В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Zabbix, через filebeat. Можно использовать logstash тоже.
4. Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

## Выполнение работы
На этом этапе вы непосредственно выполняете работу. При этом вы можете консультироваться с руководителем по поводу вопросов, требующих уточнения.

⚠️ В случае недоступности ресурсов Elastic для скачивания рекомендуется разворачивать сервисы с помощью docker контейнеров, основанных на официальных образах.

**Важно**: Ещё можно задавать вопросы по поводу того, как реализовать ту или иную функциональность. И руководитель определяет, правильно вы её реализовали или нет. Любые вопросы, которые не освещены в этом документе, стоит уточнять у руководителя. Если его требования и указания расходятся с указанными в этом документе, то приоритетны требования и указания руководителя.

## Критерии сдачи
1. Инфраструктура отвечает минимальным требованиям, описанным в [Задаче](#Задача).
2. Предоставлен доступ ко всем ресурсам, у которых предполагается веб-страница (сайт, Kibana, Zabbix).
3. Для ресурсов, к которым предоставить доступ проблематично, предоставлены скриншоты, команды, stdout, stderr, подтверждающие работу ресурса.
4. Работа оформлена в отдельном репозитории в GitHub или в [Google Docs](https://docs.google.com/), разрешён доступ по ссылке. 
5. Код размещён в репозитории в GitHub.
6. Работа оформлена так, чтобы были понятны ваши решения и компромиссы. 
7. Если использованы дополнительные репозитории, доступ к ним открыт. 

## Как правильно задавать вопросы дипломному руководителю
Что поможет решить большинство частых проблем:
1. Попробовать найти ответ сначала самостоятельно в интернете или в материалах курса и только после этого спрашивать у дипломного руководителя. Навык поиска ответов пригодится вам в профессиональной деятельности.
2. Если вопросов больше одного, присылайте их в виде нумерованного списка. Так дипломному руководителю будет проще отвечать на каждый из них.
3. При необходимости прикрепите к вопросу скриншоты и стрелочкой покажите, где не получается. Программу для этого можно скачать [здесь](https://app.prntscr.com/ru/).

Что может стать источником проблем:
1. Вопросы вида «Ничего не работает. Не запускается. Всё сломалось». Дипломный руководитель не сможет ответить на такой вопрос без дополнительных уточнений. Цените своё время и время других.
2. Откладывание выполнения дипломной работы на последний момент.
3. Ожидание моментального ответа на свой вопрос. Дипломные руководители — работающие инженеры, которые занимаются, кроме преподавания, своими проектами. Их время ограничено, поэтому постарайтесь задавать правильные вопросы, чтобы получать быстрые ответы :)

</details>


## I. Подготовка и установка TERRAFORM, ANSIBLE.

### a) Terraform

```python
wget https://hashicorp-releases.yandexcloud.net/terraform/1.14.0-alpha20250911/terraform_1.14.0-alpha20250911_linux_amd64.zip 
wget https://hashicorp-releases.yandexcloud.net/terraform/1.14.0-alpha20250911/terraform_1.14.0-alpha20250911_SHA256SUMS
sha256sum -c --ignore-missing terraform_1.14.0-alpha20250911_SHA256SUMS
sudo unzip terraform_1.14.0-alpha20250911_linux_amd64.zip -d /usr/local/bin
terraform version
```
![1](img/1.png)

```python
nano ~/.terraformrc
```
![2](img/2.png)

```python
ssh-keygen -t ed25519
cat ~/.ssh/id_ed25519.pub
```
 
```python
nano ~/meta.yaml
```
![3](img/3.png)

Создание `playbook Terraform` с провайдером.
```python
nano ~/providers.tf
```
![4](img/4.png)

```python
terraform init
```
![5](img/5.png)

### b) Ansible

```python
mkdir .ansible/
cd .ansible/
sudo apt install ansible
ansible --version
```
![6](img/6.png)

Создание `ansible.cfg` 
```python
sudo nano ansible.cfg
```
![7](img/7.png)

---------

## II. Настройки для развёртывания инфраструктуры с помощью TERRAFORM.

### a) Сайт. Серверы Nginx.

Создаются:

```python
sudo nano ...tf
```

- [main.tf](https://github.com/stimul2520/sys43-diplom/blob/9864edf12f7a3734e85353e614e2acf33bf99433/terraform/main.tf), в котором описывается создание 2 ВМ с nginx.
- [target.tf](https://github.com/stimul2520/sys43-diplom/blob/9864edf12f7a3734e85353e614e2acf33bf99433/terraform/target.tf), создание целевых групп.
- [backend.tf](https://github.com/stimul2520/sys43-diplom/blob/a5b983ed773ac9de613d0397b32cf99272b61b19/terraform/backend.tf), группы бэкендов.
- [router.tf](https://github.com/stimul2520/sys43-diplom/blob/c7c91766226b32fe9b269c78dc0fadeb7ebe8bbd/terraform/router.tf), HTTP роутер.
- [balancer.tf](https://github.com/stimul2520/sys43-diplom/blob/c7c91766226b32fe9b269c78dc0fadeb7ebe8bbd/terraform/balancer.tf), Application Load Balancer.

### b) Мониторинг. Zabbix.

Создание ВМ, развертывание на ней Zabbix. На каждую ВМ установка Zabbix Agent, настройка агентов на отправление метрик в Zabbix.

- [zabbix.tf](https://github.com/stimul2520/sys43-diplom/blob/c7c91766226b32fe9b269c78dc0fadeb7ebe8bbd/terraform/zabbix.tf)

### с) Логи. Elasticsearch, Kibana.

1. Cоздание ВМ, развертывание на ней Elasticsearch.
2. Создание ВМ, развертывание на ней Kibana, конфигурация соединение с Elasticsearch.

- [elastic.tf](https://github.com/stimul2520/sys43-diplom/blob/c7c91766226b32fe9b269c78dc0fadeb7ebe8bbd/terraform/elastic.tf)
- [kibana.tf](https://github.com/stimul2520/sys43-diplom/blob/c7c91766226b32fe9b269c78dc0fadeb7ebe8bbd/terraform/kibana.tf)

### d) Сеть.

1. Развертывание одного VPC. 
2. Сервера web, Elasticsearch помещаются в приватные подсети. 
3. Сервера Zabbix, Kibana, application load balancer определяются в публичную подсеть.
4. Настройка Security Groups соответствующих сервисов на входящий трафик только к нужным портам.
5. Настройка ВМ с публичным адресом, в которой будет открыт только один порт — ssh. Эта вм будет реализовывать концепцию bastion host .

- [network.tf](https://github.com/stimul2520/sys43-diplom/blob/c7c91766226b32fe9b269c78dc0fadeb7ebe8bbd/terraform/network.tf)
- [security.tf](https://github.com/stimul2520/sys43-diplom/blob/c7c91766226b32fe9b269c78dc0fadeb7ebe8bbd/terraform/security.tf)
- [bastion.tf](https://github.com/stimul2520/sys43-diplom/blob/c7c91766226b32fe9b269c78dc0fadeb7ebe8bbd/terraform/bastion.tf)

### e) Резервное копирование.

1. Создание snapshot дисков всех ВМ. 
2. Ограничение времени жизни snaphot в неделю. Сами snaphot настраиваются на ежедневное копирование.

- [snapshot.tf](https://github.com/stimul2520/sys43-diplom/blob/697163b8fc84499b376548a5ec29d4e951159fde/terraform/snapshot.tf)

### f) Вывод информации в консоль по созданию ВМ.

- [outputs.tf](https://github.com/stimul2520/sys43-diplom/blob/c7c91766226b32fe9b269c78dc0fadeb7ebe8bbd/terraform/outputs.tf)

---------

## III. Поднятие облачной инфраструктуры с помощью TERRAFORM.

```python
terraform plan
terraform apply
```
![10](img/10.png)
![11](img/11.png)
![12](img/12.png)
![13](img/13.png)
![14](img/14.png)
![15](img/15.png)

---------

## IV. Настройки для развёртывания инфраструктуры с помощью ANSIBLE.

Создание и настройка [hosts](/home/diploma1/sys43-diplom/ansible/hosts), [ansible.cfg](https://github.com/stimul2520/sys43-diplom/blob/8c291abcbf88bf50f157887d514af1c6d74a5a6b/ansible/ansible.cfg).

```python
cd .ansible/
sudo nano hosts
sudo nano ansible.cfg
```

Проверка доступности хостов:
```python
sudo ansible all -m ping --list-hosts
ansible all -m ping
```
![16](img/16.png)
![17](img/17.png)
![18](img/18.png)

Создание, запуск ansible-playbooks и сопутствующих конфиг файлов.

1. Nginx.
- [ngx1.html](https://github.com/stimul2520/sys43-diplom/blob/8c291abcbf88bf50f157887d514af1c6d74a5a6b/ansible/ngx1.html)
- [ngx2.html](https://github.com/stimul2520/sys43-diplom/blob/8c291abcbf88bf50f157887d514af1c6d74a5a6b/ansible/ngx2.html)
- [nginx-playbook.yaml](https://github.com/stimul2520/sys43-diplom/blob/8c291abcbf88bf50f157887d514af1c6d74a5a6b/ansible/nginx-playbook.yaml)

![19](img/19.png)
![20](img/20.png)

2. Elasticsearch (https://mirror.yandex.ru/mirrors/elastic/7/pool/main/e/elasticsearch/elasticsearch-7.17.1-amd64.deb)
- [elastic-conf.yaml](https://github.com/stimul2520/sys43-diplom/blob/8c291abcbf88bf50f157887d514af1c6d74a5a6b/ansible/elastic-conf.yaml)
- [elastic-play.yaml](https://github.com/stimul2520/sys43-diplom/blob/8c291abcbf88bf50f157887d514af1c6d74a5a6b/ansible/elastic-play.yaml)

![21](img/21.png)

3. Kibana (https://mirror.yandex.ru/mirrors/elastic/7/pool/main/k/kibana/kibana-7.17.1-amd64.deb)
- [kibana.j2](https://github.com/stimul2520/sys43-diplom/blob/8c291abcbf88bf50f157887d514af1c6d74a5a6b/ansible/kibana.j2)
- [kibana-play.yaml](https://github.com/stimul2520/sys43-diplom/blob/8c291abcbf88bf50f157887d514af1c6d74a5a6b/ansible/kibana-play.yaml)

![22](img/22.png)

4. Filebeat (https://mirror.yandex.ru/mirrors/elastic/7/pool/main/f/filebeat/filebeat-7.17.1-amd64.deb)
- [filebeat.j2](https://github.com/stimul2520/sys43-diplom/blob/8c291abcbf88bf50f157887d514af1c6d74a5a6b/ansible/filebeat.j2)
- [filebeat-play.yaml](https://github.com/stimul2520/sys43-diplom/blob/8c291abcbf88bf50f157887d514af1c6d74a5a6b/ansible/filebeat-play.yaml)

![23](img/23.png)

5. Zabbix. Zabbix-agent.
- [zabbix-playbook.yaml](https://github.com/stimul2520/sys43-diplom/blob/8c291abcbf88bf50f157887d514af1c6d74a5a6b/ansible/zabbix-playbook.yaml)
- [zabbix-agent-playbook.yaml](https://github.com/stimul2520/sys43-diplom/blob/8c291abcbf88bf50f157887d514af1c6d74a5a6b/ansible/zabbix-agent-playbook.yaml)

![24](img/24.png)
![25](img/25.png)
![26](img/26.png)
![27](img/27.png)

---------

## V. Проверка и настройка ресурсов.


