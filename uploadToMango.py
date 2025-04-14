import os
from pymongo import MongoClient
from gridfs import GridFSBucket
from datetime import datetime


def upload_all_files_in_directory(directory_path='files',
                                  db_name='file_database',
                                  mongodb_uri='mongodb://admin:admin@localhost:27017/'):
    """
    上传指定目录下的所有文件到GridFS

    参数:
        directory_path: 包含要上传文件的目录路径
        db_name: 数据库名称
        mongodb_uri: MongoDB连接URI
    """
    # 连接MongoDB
    client = MongoClient(mongodb_uri)
    db = client[db_name]
    bucket = GridFSBucket(db)

    # 确保目录存在
    if not os.path.exists(directory_path):
        print(f"目录不存在: {directory_path}")
        return []

    if not os.path.isdir(directory_path):
        print(f"提供的路径不是目录: {directory_path}")
        return []

    # 获取目录下所有文件
    file_paths = []
    for root, _, files in os.walk(directory_path):
        for filename in files:
            file_path = os.path.join(root, filename)
            file_paths.append(file_path)

    if not file_paths:
        print(f"目录中没有可上传的文件: {directory_path}")
        return []

    print(f"准备上传 {len(file_paths)} 个文件...")

    results = []

    for file_path in file_paths:
        try:
            # 获取文件基本信息
            filename = os.path.basename(file_path)
            file_size = os.path.getsize(file_path)
            file_ext = os.path.splitext(filename)[1].lower()

            # 确定内容类型
            content_type = "application/octet-stream"  # 默认类型
            if file_ext in ['.pptx', '.ppt']:
                content_type = 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
            elif file_ext == '.pdf':
                content_type = 'application/pdf'
            elif file_ext in ['.jpg', '.jpeg']:
                content_type = 'image/jpeg'
            elif file_ext == '.png':
                content_type = 'image/png'

            # 准备元数据
            metadata = {
                "content_type": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
                "author": "Your Name",
                "custom_field": "any_value"
            }

            # 上传文件
            with open(file_path, 'rb') as file_to_upload:
                upload_stream = bucket.open_upload_stream(
                    filename=filename,
                    metadata=metadata
                )

                # 分块上传文件
                chunk_size = 255 * 1024  # 255KB
                while True:
                    chunk = file_to_upload.read(chunk_size)
                    if not chunk:
                        break
                    upload_stream.write(chunk)

                upload_stream.close()
                file_id = upload_stream._id

                # 记录结果
                result = {
                    "status": "success",
                    "file_id": str(file_id),
                    "filename": filename,
                    "file_path": file_path,
                    "size": file_size,
                    "content_type": content_type
                }
                results.append(result)

                print(f"上传成功: {filename} (ID: {file_id})")

        except Exception as e:
            error_result = {
                "status": "failed",
                "filename": filename,
                "file_path": file_path,
                "error": str(e)
            }
            results.append(error_result)
            print(f"上传失败: {filename} - {str(e)}")

    # 打印汇总信息
    success_count = len([r for r in results if r['status'] == 'success'])
    fail_count = len(results) - success_count

    print("\n上传完成!")
    print(f"成功: {success_count} 个文件")
    print(f"失败: {fail_count} 个文件")

    return results


if __name__ == "__main__":
    # 使用示例 - 上传当前目录下的files文件夹中的所有文件
    upload_results = upload_all_files_in_directory('files')

    # 可选: 将结果保存到文件
    import json

    with open('upload_results.json', 'w') as f:
        json.dump(upload_results, f, indent=2, default=str)