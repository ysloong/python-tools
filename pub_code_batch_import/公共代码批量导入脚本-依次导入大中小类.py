import pandas as pd
import os
import psycopg2
from string import Template

# 依次导入大类，中类，小类

# 准备工作 start--------------------------------------------------
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

parent_dgov_category_id =get_ds_category_id() 
ds_hierarchy_id =get_ds_hierarchy_id() 

# 准备工作 end--------------------------------------------------

xls =  pd.ExcelFile(excel_file_path)
variables_sheet = xls.parse('变量')
cls_sheet = xls.parse('类目')

# 读取Excel文件
variables_sheet = pd.read_excel(excel_file_path,sheet_name='变量')
# 将'变量名'设置为索引，然后将'变量值'列转换为字典
variables_map = variables_sheet.set_index('变量名')['变量值'].to_dict()
user_id =variables_map.get('user_id') 
tenant_id =variables_map.get('tenant_id') 

#-------------------------------------------------------------------------------------------------------------------------

# 1 读取大类
big_cls_rows = cls_sheet.drop_duplicates(subset='大类')
num_ids_needed = len(big_cls_rows)
# 直接在 DataFrame 创建时应用转换
big_cls_result_df = pd.DataFrame({
    '大类': big_cls_rows['大类'],
    '大类雪花id': [id_tuple[0] for id_tuple in snow_next_id(count=num_ids_needed)]
})


# 生成所有的插入语句
insert_statements = [
    insert_template.substitute(
        ds_hierarchy_id=ds_hierarchy_id,
        parent_dgov_category_id=parent_dgov_category_id,
        category_num=row.name,  # 使用索引作为 category_nume
        seq_num=row.name,       # 使用索引作为 seq_num
        cn_name=row['大类'],
        tenant_id=tenant_id,
        creator=user_id,
        ds_category_id=row['大类雪花id']
    ) + "\n"
    for _, row in big_cls_result_df.iterrows()
]

# 连接所有的插入语句并写入文件
with open(sql_file_path, 'w', encoding='utf-8') as f:
    f.write("".join(insert_statements))
    f.write("\n---------------------------------------------大类end-----------------------------------------\n")

# 读取中类
# # 去除中类列的NaN值，然后进行去重，同时保留与之对应的'大类'
mid_cls_rows = cls_sheet.drop_duplicates(subset='中类')
mid_cls_rows = mid_cls_rows[['大类', '中类']]
num_ids_needed = len(mid_cls_rows)

# 直接在 DataFrame 创建时应用转换
mid_cls_result_df = pd.DataFrame({
    '大类': mid_cls_rows['大类'],
    '中类': mid_cls_rows['中类'],
    '中类雪花id': [id_tuple[0] for id_tuple in snow_next_id(count=num_ids_needed)]
}).dropna(subset=['中类'])
mid_cls_result_df['大类雪花id'] = mid_cls_result_df['大类'].map(big_cls_result_df.set_index('大类')['大类雪花id'].apply(str).to_dict())
print(mid_cls_result_df)

# 生成所有的插入语句
insert_statements = [
    insert_template.substitute(
        ds_hierarchy_id=ds_hierarchy_id,
        parent_dgov_category_id=row['大类雪花id'],
        category_num=row.name,  # 使用索引作为 category_nume
        seq_num=row.name,       # 使用索引作为 seq_num
        cn_name=row['中类'],
        tenant_id=tenant_id,
        creator=user_id,
        ds_category_id=row['中类雪花id']
    ) + "\n"
    for _, row in mid_cls_result_df.iterrows()
]


# 连接所有的插入语句并写入文件
with open(sql_file_path, 'a', encoding='utf-8') as f:
    f.write("".join(insert_statements))
    f.write("\n---------------------------------------------中类end-----------------------------------------\n")


# 读取小类
# # 去除中类列的NaN值，然后进行去重，同时保留与之对应的'大类'
lit_cls_rows = cls_sheet.drop_duplicates(subset='小类')
lit_cls_rows = lit_cls_rows[['中类', '小类']]
num_ids_needed = len(lit_cls_rows)

# 直接在 DataFrame 创建时应用转换
lit_cls_result_df = pd.DataFrame({
    '中类': lit_cls_rows['中类'],
    '小类': lit_cls_rows['小类'],
    '小类雪花id': [id_tuple[0] for id_tuple in snow_next_id(count=num_ids_needed)]
}).dropna(subset=['小类'])

lit_cls_result_df['中类雪花id'] = lit_cls_result_df['中类'].map(mid_cls_result_df.set_index('中类')['中类雪花id'].apply(str).to_dict())
print(lit_cls_result_df)



# 生成所有的插入语句
insert_statements = [
    insert_template.substitute(
        ds_hierarchy_id=ds_hierarchy_id,
        parent_dgov_category_id=row['中类雪花id'],
        category_num=row.name,  # 使用索引作为 category_nume
        seq_num=row.name,       # 使用索引作为 seq_num
        cn_name=row['小类'],
        tenant_id=tenant_id,
        creator=user_id,
        ds_category_id=row['小类雪花id']
    ) + "\n"
    for _, row in lit_cls_result_df.iterrows()
]


# 连接所有的插入语句并写入文件
with open(sql_file_path, 'a', encoding='utf-8') as f:
    f.write("".join(insert_statements))
    f.write("\n---------------------------------------------小类end-----------------------------------------\n")    


# 生成所有的插入语句
# insert_statements = [
#     insert_template.substitute(
#         ds_hierarchy_id=ds_hierarchy_id,
#         parent_dgov_category_id=row['大类雪花id'],
#         category_num=row.name,  # 使用索引作为 category_nume
#         seq_num=row.name,       # 使用索引作为 seq_num
#         cn_name=row['中类'],
#         tenant_id=tenant_id,
#         creator=user_id,
#         ds_category_id=row['中类雪花id']
#     ) + "\n"
#     for _, row in result_df.iterrows()
# ]





# with open(sql_file_path, 'w', encoding='utf-8') as f: 
#     for _, row in result_df.iterrows():
#         insert_statement = insert_template.substitute(
#             ds_hierarchy_id = ds_hierarchy_id,
#             parent_dgov_category_id = parent_dgov_category_id,
#             category_num = _,
#             seq_num = _,
#             cn_name=row['大类'],
#             tenant_id = tenant_id,
#             creator = user_id,
#             ds_category_id=row['大类雪花id']
#         )
#         f.write(insert_statement)
#         f.write("\n);\n\n")
#     f.write("\n---------------------------------------------大类end-----------------------------------------\n")    




#  # 直接在生成元组时处理空值和转换ID
# unique_big_categories = [category for category in cls_sheet['大类'].dropna().unique().tolist() if category]
# num_ids_needed = len(unique_big_categories)
# snowflake_ids = snow_next_id(num_ids_needed)
        
# # 将类别与对应的雪花ID配对
# simplified_list = [(category, id_[0]) for category, id_ in zip(unique_big_categories, snowflake_ids)]
# dict_big_cls = dict(simplified_list)
# print('------------------大类词典--------------------------')
# print(dict(simplified_list))

# # 2 读取中类
# # 去除中类列的NaN值，然后进行去重，同时保留与之对应的'大类'
# selected_rows = cls_sheet.drop_duplicates(subset='中类')
# selected_columns = selected_rows[['大类', '中类']]
# num_ids_needed = len(selected_columns)
# snowflake_ids = snow_next_id(num_ids_needed)

# result_df = pd.DataFrame({
#     '大类': selected_columns['大类'],
#     '中类': selected_columns['中类'],
#     '雪花ID': snowflake_ids
# })
# result_df['父类雪花id'] = result_df['大类'].map(dict_big_cls)
# result_df['雪花ID'] = result_df['雪花ID'].apply(lambda x: x[0])


# print('------------------中类词典--------------------------')

# category_snowflake_dict = {row['中类']: row['雪花ID'] for _, row in result_df.iterrows()}
# print(category_snowflake_dict)


# # 2 读取小类
# # 去除中类列的NaN值，然后进行去重，同时保留与之对应的'大类'
# selected_rows = cls_sheet.drop_duplicates(subset='小类')

# selected_columns = selected_rows[['大类', '中类', '小类']]

# num_ids_needed = len(selected_columns)
# snowflake_ids = snow_next_id(num_ids_needed)


# result_df = pd.DataFrame({
#     '大类': selected_columns['大类'],
#     '中类': selected_columns['中类'],
#     '小类': selected_columns['小类'],
#     '雪花ID': snowflake_ids
# })

# result_df['大类雪花id'] = result_df['大类'].map(dict_big_cls)
# result_df['中类雪花id'] = result_df['中类'].map(category_snowflake_dict)
# result_df['雪花ID'] = result_df['雪花ID'].apply(lambda x: x[0])
# print(result_df)

# print('------------------变量--------------------------')
# big_cls_with_id = result_df[['大类','大类雪花id']]

# mid_cls_with_id = result_df[['大类雪花id','中类','中类雪花id']].dropna(how='any')
# little_cls_with_id = result_df[['中类雪花id','小类','雪花ID']].dropna(how='any')





# with open(sql_file_path, 'w', encoding='utf-8') as f:
#     for _, row in big_cls_with_id.iterrows():
#         insert_statement = insert_template.substitute(
#             ds_hierarchy_id = ds_hierarchy_id,
#             parent_dgov_category_id = parent_dgov_category_id,
#             category_num = _,
#             seq_num = _,
#             cn_name=row['大类'],
#             tenant_id = tenant_id,
#             creator = user_id,
#             ds_category_id=row['大类雪花id']
#         )
#         f.write(insert_statement)
#         f.write("\n);\n\n")

