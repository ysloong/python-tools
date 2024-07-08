import pandas as pd
import os
import psycopg2
# from string import Template


db_config = {
    "dbname": "postgres",
    "user": "postgres",
    "password": "ysl123@@",
    "host": "192.168.10.121",  # 或者是数据库的实际地址
    "port": "5432"  # 默认端口是5432，根据实际情况修改
}

conn = psycopg2.connect(**db_config)
cur = conn.cursor()

def snow_next_id(count):
    cur.execute(f"SELECT data_standard.snow_next_id() FROM generate_series(1, {count})")
    retuslt= cur.fetchall()
    conn.commit()
    return retuslt

# 获取当前脚本所在目录
script_dir = os.path.dirname(os.path.abspath(__file__))

# 构建Excel文件的路径，假设Excel文件就在脚本的同一目录下
excel_file_path = os.path.join(script_dir, "公共代码数据.xlsx")

xls =  pd.ExcelFile(excel_file_path)
variables_sheet = xls.parse('变量')
cls_sheet = xls.parse('类目')

# 1 读取大类

 # 直接在生成元组时处理空值和转换ID
unique_big_categories = [category for category in cls_sheet['大类'].dropna().unique().tolist() if category]
num_ids_needed = len(unique_big_categories)
snowflake_ids = snow_next_id(num_ids_needed)
        
# 将类别与对应的雪花ID配对
simplified_list = [(category, id_[0]) for category, id_ in zip(unique_big_categories, snowflake_ids)]
dict_big_cls = dict(simplified_list)
print('------------------大类词典--------------------------')
print(dict(simplified_list))

# 2 读取中类]
# 去除中类列的NaN值，然后进行去重，同时保留与之对应的'大类'
selected_rows = cls_sheet.drop_duplicates(subset='中类')
selected_columns = selected_rows[['大类', '中类']]
num_ids_needed = len(selected_columns)
snowflake_ids = snow_next_id(num_ids_needed)

result_df = pd.DataFrame({
    '大类': selected_columns['大类'],
    '中类': selected_columns['中类'],
    '雪花ID': snowflake_ids
})
result_df['父类雪花id'] = result_df['大类'].map(dict_big_cls)
result_df['雪花ID'] = result_df['雪花ID'].apply(lambda x: x[0])
# print('------------------大类+中类--------------------------')
# print(result_df)

print('------------------中类词典--------------------------')

category_snowflake_dict = {row['中类']: row['雪花ID'] for _, row in result_df.iterrows()}
print(category_snowflake_dict)


# 2 读取小类
# 去除中类列的NaN值，然后进行去重，同时保留与之对应的'大类'
selected_rows = cls_sheet.drop_duplicates(subset='小类')

selected_columns = selected_rows[['大类', '中类', '小类']]

num_ids_needed = len(selected_columns)
snowflake_ids = snow_next_id(num_ids_needed)


result_df = pd.DataFrame({
    '大类': selected_columns['大类'],
    '中类': selected_columns['中类'],
    '小类': selected_columns['小类'],
    '雪花ID': snowflake_ids
})

result_df['大类雪花id'] = result_df['大类'].map(dict_big_cls)
result_df['中类雪花id'] = result_df['中类'].map(category_snowflake_dict)
result_df['雪花ID'] = result_df['雪花ID'].apply(lambda x: x[0])
print(result_df)

print('------------------变量--------------------------')
big_cls_with_id = result_df[['大类','大类雪花id']]
print(big_cls_with_id)

mid_cls_with_id = result_df[['大类雪花id','中类','中类雪花id']]
print(mid_cls_with_id)

little_cls_with_id = result_df[['中类雪花id','小类','雪花ID']]
print(little_cls_with_id)




# 读取Excel文件
variables_sheet = pd.read_excel(excel_file_path,sheet_name='变量')
# 将'变量名'设置为索引，然后将'变量值'列转换为字典
variables_map = variables_sheet.set_index('变量名')['变量值'].to_dict()

# parent_dgov_category_id =variables_map.get('parent_dgov_category_id') 
# creator =variables_map.get('creator') 
# modifier =variables_map.get('modifier') 
# tenant_id =variables_map.get('tenant_id') 

# print(parent_dgov_category_id)
# print(creator)
# print(modifier)
# print(tenant_id)


# print(variables_map)

# # 读取类目sheet
# cls_sheet = pd.read_excel(excel_file_path,sheet_name='类目')
# for index,row in cls_sheet.iterrows():
#     cn_name = row['大类']


# for index, row in variables_sheet.iterrows():
#     variable_name = row['变量名']
#     variable_value = row['变量值']
#     print(f'{variable_name} = {variable_value}')







# # 假设Excel文件名为excel_file.xlsx，且已知sheet名分别为'sheet_category'和'sheet_variables'
# excel_file = '公共代码数据.xlsx'

# # 读取列大类信息的sheet
# category_sheet = pd.read_excel(excel_file, sheet_name='sheet_category')
# cn_name = category_sheet.iloc[0]['cn_name']  # 假设第一行是标题行，cn_name在第二行

# # 读取变量名和变量值的sheet
# variables_sheet = pd.read_excel(excel_file, sheet_name='sheet_variables')

# # 构建变量值字典
# values_dict = variables_sheet.set_index('variable_name')['variable_value'].to_dict()

# # 定义INSERT语句模板
# insert_template = Template("""
# INSERT INTO samp.ds_std_category (
#     ds_category_id, ds_hierarchy_id, category_num, cn_name, en_name, en_abbr, 
#     parent_dgov_category_id, "level", seq_num, "describe", preorder_dgov_category_id, 
#     follow_dgov_category_id, tenant_id, if_delete, creator, create_tm, modifier, 
#     modify_tm, cn_abbr, biz_sys_id
# ) 
# VALUES(
#     snow_next_id(), 175142360110354433, '', '$cn_name$', '', '', 769245727686791168,
#     -1, 2, '', NULL, NULL, 1167337764142780417, '0', 
#     133229490020159488, now(), 133229490020159488, now(), '', NULL
# );
# """)

# # 替换模板中的变量
# insert_statement = insert_template.substitute(cn_name=cn_name)

# # 如果需要进一步替换其他变量值，请根据实际情况调整下面的逻辑
# # 例如，如果variables_sheet中有更多与INSERT语句中变量名匹配的值，可以遍历values_dict并替换
# for key, value in values_dict.items():
#     placeholder = f'${key}$'  # 构建占位符
#     if placeholder in insert_statement:
#         insert_statement = insert_statement.replace(placeholder, str(value))

# print(insert_statement)


# [('一般公共预算支出科目', 252374423288434691), ('一般公共预算收入科目', 252374423292628996), ('通用代码',252374423292628997)]