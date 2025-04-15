import gridfs
from pymongo import MongoClient

client = MongoClient('mongodb://admin:admin@localhost:27017/')
db = client["file_database"]
fs = gridfs.GridFS(db)

# 获取所有文件信息
file_list = fs.find()

print("GridFS 文件列表（含 ObjectId）：")
for file in file_list:
    print(f"文件名: {file.filename}, 文件ID: {file._id}")