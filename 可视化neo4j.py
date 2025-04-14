import pymysql
from py2neo import Graph, Node, Relationship
from py2neo.database import Transaction

# Neo4j连接配置
neo4j_graph = Graph("bolt://localhost:7687", auth=("neo4j", "logo-carrot-algebra-soda-tripod-8503"))


def migrate_entity_to_neo4j(mysql_conn):
    """迁移实体数据到Neo4j"""
    try:
        with mysql_conn.cursor() as cursor:
            cursor.execute("SELECT * FROM entities")
            entities = cursor.fetchall()

            # 使用单个事务处理所有节点创建
            tx = neo4j_graph.begin()
            try:
                for entity in entities:
                    entity_id, name, entity_type, description, _, _ = entity
                    node = Node("Entity",
                                id=entity_id,
                                name=name,
                                type=entity_type,
                                description=description)
                    tx.create(node)
                tx.commit()
            except Exception as e:
                tx.rollback()
                print(f"创建节点时出错: {e}")
                raise
    except Exception as e:
        print(f"查询MySQL实体数据时出错: {e}")
        raise


def migrate_relations_to_neo4j(mysql_conn):
    """迁移关系到Neo4j"""
    try:
        with mysql_conn.cursor() as cursor:
            cursor.execute("""
                SELECT r.relation_id, r.relation_type, r.description, 
                       e1.entity_name as source_name, e2.entity_name as target_name
                FROM relations r
                JOIN entities e1 ON r.source_entity_id = e1.entity_id
                JOIN entities e2 ON r.target_entity_id = e2.entity_id
            """)
            relations = cursor.fetchall()

            # 使用单个事务处理所有关系创建
            tx = neo4j_graph.begin()
            try:
                for rel in relations:
                    rel_id, rel_type, description, source_name, target_name = rel
                    source_node = neo4j_graph.nodes.match("Entity", name=source_name).first()
                    target_node = neo4j_graph.nodes.match("Entity", name=target_name).first()

                    if not source_node or not target_node:
                        print(f"警告: 找不到节点 {source_name} 或 {target_name}，跳过关系 {rel_id}")
                        continue

                    relationship = Relationship(source_node, rel_type, target_node,
                                                description=description)
                    tx.create(relationship)
                tx.commit()
            except Exception as e:
                tx.rollback()
                print(f"创建关系时出错: {e}")
                raise
    except Exception as e:
        print(f"查询MySQL关系数据时出错: {e}")
        raise


if __name__ == "__main__":
    mysql_conn = None
    try:
        # MySQL连接配置
        mysql_conn = pymysql.connect(
            host='localhost',
            user='root',
            password='root',
            database='knowledge',
        )

        # 执行迁移
        migrate_entity_to_neo4j(mysql_conn)
        migrate_relations_to_neo4j(mysql_conn)

        print("数据迁移完成!")
    except Exception as e:
        print(f"迁移过程中发生错误: {e}")
    finally:
        if mysql_conn:
            mysql_conn.close()