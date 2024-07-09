import pandas as pd
import os
import psycopg2
from string import Template

"""
工具说明：
    1 读取脚本同目录下的公共代码数据.xlsx文件，生成同目录下public_code_batch_insert.sql，包含insert 类目和批量删除类目的SQL脚本
    2 需要替换两个变量user_id、tenant_id
    3 读取公共代码数据.xlsx文件 中的sheet名类目，类目的列包含大类、中类、小类
    4 实现逻辑为，
        4.1 读取大类，去重复，去nan,然后生成雪花ID列表并默认大类父类雪花ID为-1
        4.2 读取大类，中类，按照中类去重复，去Nan，然后生成中类雪花ID列表，然后根据大类名增加大类雪花id
        4.3 读取中类，小类，按照小类去重复，去Nan，然后生成小类雪花ID列表，然后根据中类名增加中类雪花id
        4.4 根据insert_template 批量生成insert语句
        4.5 根据delete_sql_template delete语句用语回滚删除
"""
# 准备工作 start--------------------------------------------------

user_id =133229490020159488
tenant_id =1167337764142780417
# 1 数据库连接信息
db_config = {
    "dbname": "postgres",
    "user": "postgres",
    "password": "ysl123@@",
    "host": "192.168.10.121",  # 或者是数据库的实际地址
    "port": "5432"  # 默认端口是5432，根据实际情况修改
}

conn = psycopg2.connect(**db_config)
cur = conn.cursor()

# 2 文件路径
# 获取当前脚本所在目录
script_dir = os.path.dirname(os.path.abspath(__file__))

# 构建Excel文件的路径，假设Excel文件就在脚本的同一目录下
excel_file_path = os.path.join(script_dir, "公共代码数据.xlsx")
# 构建SQL文件的路径，假设SQL文件就在脚本的同一目录下
sql_file_path = os.path.join(script_dir, "public_code_batch_insert.sql")

# 3 函数获取ds_hierarchy_id、ds_category_id、snow_next_id
def get_ds_hierarchy_id():
    cur.execute(f"select ds_hierarchy_id from data_standard.ds_std_hierarchy where if_delete='0' and  cn_name = '公共代码';")
    retuslt= cur.fetchone()
    conn.commit()
    return retuslt[0]

def get_ds_category_id():
    cur.execute(f"select ds_category_id from data_standard.ds_std_category where if_delete='0' and  cn_name = '数据标准' and ds_hierarchy_id =  (select ds_hierarchy_id from data_standard.ds_std_hierarchy where if_delete='0' and  cn_name = '公共代码') and parent_dgov_category_id = -1;")
    retuslt= cur.fetchone()
    conn.commit()
    return retuslt[0]

def snow_next_id(count):
    cur.execute(f"SELECT data_standard.snow_next_id() FROM generate_series(1, {count})")
    retuslt= cur.fetchall()
    conn.commit()
    return retuslt


# 5 SQL模板
insert_template = Template("""INSERT INTO data_standard.ds_std_category (
                           ds_category_id, ds_hierarchy_id, category_num, cn_name, en_name, en_abbr, 
                           parent_dgov_category_id, level, seq_num, describe, preorder_dgov_category_id, follow_dgov_category_id, 
                           tenant_id, if_delete, creator, create_tm, modifier, modify_tm, 
                           cn_abbr, biz_sys_id) 
                           VALUES (
                           '$ds_category_id', '$ds_hierarchy_id', '$category_num', '$cn_name', '', '', 
                           '$parent_dgov_category_id', '1', '$seq_num', '', null, null, 
                           '$tenant_id', '0', '$creator', now()::timestamp, '$creator', now()::timestamp, 
                           '', null);""")

# 获取根目录的类ID和体系ID
parent_dgov_category_id =get_ds_category_id() 
ds_hierarchy_id =get_ds_hierarchy_id() 

# 准备工作 end--------------------------------------------------

xls =  pd.ExcelFile(excel_file_path)
cls_sheet = xls.parse('类目')

#-------------------------------------------------------------------------------------------------------------------------

# 读取大类，中类，小类类目信息
all_cls_rows = cls_sheet[['大类', '中类', '小类']]
ds_category_ids = []

# 定义一个函数来处理去重、去NaN和分配雪花ID
def process_and_assign_ids(df, cols, snow_next_id):
    # 去除NaN值
    df = df.dropna(subset=cols)
    # 去除重复值
    df = df.drop_duplicates(subset=cols)
    # 分配雪花ID
    num_ids_needed = len(df)
    df['雪花id'] = [id_tuple[0] for id_tuple in snow_next_id(count=num_ids_needed)]
    # 返回处理后的DataFrame
    return df

# 处理大类
big_cls_row = process_and_assign_ids(cls_sheet[['大类']], ['大类'], snow_next_id)
big_cls_row.rename(columns={'雪花id': '大类雪花id'}, inplace=True)
big_cls_row['大类父雪花id'] =parent_dgov_category_id
ds_category_ids = ds_category_ids + list(big_cls_row['大类雪花id'])

# 处理中类，同时映射大类雪花ID
mid_cls_row = process_and_assign_ids(cls_sheet[['大类', '中类']], ['大类', '中类'], snow_next_id)
mid_cls_row.rename(columns={'雪花id': '中类雪花id'}, inplace=True)
mid_cls_row['大类雪花id'] = mid_cls_row['大类'].map(big_cls_row.set_index('大类')['大类雪花id'].to_dict())
ds_category_ids = ds_category_ids + list(mid_cls_row['中类雪花id'])

# 处理小类，同时映射中类雪花ID
lit_cls_row = process_and_assign_ids(cls_sheet[['中类', '小类']], ['中类', '小类'], snow_next_id)
lit_cls_row.rename(columns={'雪花id': '小类雪花id'}, inplace=True)
lit_cls_row['中类雪花id'] = lit_cls_row['中类'].map(mid_cls_row.set_index('中类')['中类雪花id'].to_dict())

ds_category_ids = ds_category_ids + list(lit_cls_row['小类雪花id'])

def generate_insert_statements(df, parent_id_col, category_col, category_id_col):
    return [
        insert_template.substitute(
            ds_hierarchy_id=ds_hierarchy_id,
            parent_dgov_category_id=df.loc[row.name, parent_id_col],  # 使用.loc确保正确获取值
            category_num=row.name,
            seq_num=row.name,
            cn_name=row[category_col],
            tenant_id=tenant_id,
            creator=user_id,
            ds_category_id=row[category_id_col]
        ) + "\n"
        for _, row in df.iterrows()
    ]

# 生成大类的插入语句
big_cls_statements = generate_insert_statements(
    big_cls_row, 
    '大类父雪花id', 
    '大类', 
    '大类雪花id'
)

# 生成中类的插入语句
mid_cls_statements = generate_insert_statements(
    mid_cls_row, 
    '大类雪花id', 
    '中类', 
    '中类雪花id'
)

# 生成小类的插入语句
lit_cls_statements = generate_insert_statements(
    lit_cls_row, 
    '中类雪花id', 
    '小类', 
    '小类雪花id'
)

# 合并所有语句
insert_statements = big_cls_statements + mid_cls_statements + lit_cls_statements
# 连接所有的插入语句并写入文件
with open(sql_file_path, 'w', encoding='utf-8') as f:
    f.write("".join(insert_statements))
    f.write("\n---------------------------------------------大类end-----------------------------------------\n")

print("---------------------------------------------批量回滚删除start-----------------------------------------")
ds_category_ids = ', '.join(map(str, ds_category_ids))
delete_sql_template = Template("DELETE FROM data_standard.ds_std_category WHERE ds_category_id IN ($ids);")
sql_query = delete_sql_template.substitute(ids=ds_category_ids)


# # print(delete_template)
# # 连接所有的插入语句并写入文件
with open(sql_file_path, 'a', encoding='utf-8') as f:
    f.write(sql_query)
    f.write("\n---------------------------------------------回滚删除end-----------------------------------------\n")

