# GKE Upgrade Detector

GKEクラスタのアップグレード通知をメールで受信します。
https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-upgrade-notifications?hl=ja

下記のGCPサービスを使用します。
・Cloud Pub/Sub
・Cloud Functions
・Stackdriver Logging
・Stackdriver Monitoring

## 前提条件

Terraform 0.14.2を使用します。

## 環境構築

### 1. 初期設定

Terraform実行用サービスアカウントを作成します。

```
gcloud iam service-accounts create terraform
```

サービスアカウントに権限を付与します。

```
gcloud projects add-iam-policy-binding <PROJECT_ID> --member="serviceAccount:terraform@<PROJECT_ID>.iam.gserviceaccount.com" --role="roles/editor"
gcloud projects add-iam-policy-binding <PROJECT_ID> --member="serviceAccount:terraform@<PROJECT_ID>.iam.gserviceaccount.com" --role="roles/resourcemanager.projectIamAdmin"
```

キーファイルを作成します。

```
gcloud iam service-accounts keys create terraform-key.json --iam-account=terraform@<PROJECT_ID>.iam.gserviceaccount.com
```

環境変数を使用して認証情報を設定します。

```
export GOOGLE_APPLICATION_CREDENTIALS="terraform-key.json"
```

```
terraform init
```

### 2. 環境構築

main.tfvarsの<PROJECT_ID><BUCKET_NAME><MAIL_ADDRESS>を設定します。

Terraformを実行します。

```
terraform plan -var-file=main.tfvars
```

```
terraform apply -var-file=main.tfvars
```

GKEアップグレード通知を有効にします。

```
gcloud beta container clusters update cluster --notification-config=pubsub=ENABLED,pubsub-topic=projects/<PROJECT_ID>/topics/gke-upgrade-notification
```

## 動作確認

クラスタのノードプールをアップグレードします。

```
gcloud container clusters upgrade cluster --cluster-version <VERSION> --node-pool pool
```

## クリーンアップ

```
terraform destroy -var-file=main.tfvars
```