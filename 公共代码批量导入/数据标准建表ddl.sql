select current_database(),current_schema;

create schema data_standard;

set search_path to data_standard;


CREATE SEQUENCE table_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 99999999
	START 1
	CACHE 1
	CYCLE;



-- DROP FUNCTION snow_next_id(out int8);

CREATE OR REPLACE FUNCTION snow_next_id(OUT result bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
   our_epoch_millis bigint := extract(epoch from date '2022-08-09')*1000 ;/*1314220021721;系统初始时间；项目初始时间2022-08-09*/
   seq_id bigint;/*序列数*/
   now_millis bigint;/*当前毫秒*/
   shard_id int := 5;/*机器码？5=0b0101。留10位共1024个选择*/
BEGIN
   seq_id := nextval('table_id_seq') % 4096;/*模1024；改为4096保证数量在4096内*/
   SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
   result := (now_millis - our_epoch_millis) << 22;/*时间差（毫秒）左移22位*/
   result := result | (shard_id << 12); /*|是二进制or运算； <<是左移 12位*/
   result := result | (seq_id);
END;
$function$
;



CREATE TABLE ds_std_hierarchy (
	ds_hierarchy_id int8 NOT NULL, -- 数据标准体系标识
	cn_name varchar(500) NOT NULL, -- 中文名称
	hierarchy_type_cd varchar(30) NOT NULL, -- 体系类型代码
	hierarchy_show_cd varchar(30) NOT NULL, -- 体系展现代码
	tenant_id int8 NOT NULL, -- 租户标识
	if_delete varchar(1) NOT NULL, -- 是否删除记录
	creator int8 NOT NULL, -- 记录创建人
	create_tm timestamp NOT NULL, -- 记录创建时间
	modifier int8 NOT NULL, -- 记录修改人
	modify_tm timestamp NOT NULL, -- 记录修改时间
	cn_abbr varchar(500) NOT NULL DEFAULT ''::character varying, -- 中文简称
	en_name varchar(500) NOT NULL DEFAULT ''::character varying, -- 英文名称
	en_abbr varchar(500) NOT NULL DEFAULT ''::character varying, -- 英文简称
	"describe" text NOT NULL DEFAULT ''::text, -- 描述
	CONSTRAINT ds_std_hierarchy_pkey PRIMARY KEY (ds_hierarchy_id)
);
COMMENT ON TABLE ds_std_hierarchy IS '标准体系';

-- Column comments

COMMENT ON COLUMN ds_std_hierarchy.ds_hierarchy_id IS '数据标准体系标识';
COMMENT ON COLUMN ds_std_hierarchy.cn_name IS '中文名称';
COMMENT ON COLUMN ds_std_hierarchy.hierarchy_type_cd IS '体系类型代码';
COMMENT ON COLUMN ds_std_hierarchy.hierarchy_show_cd IS '体系展现代码';
COMMENT ON COLUMN ds_std_hierarchy.tenant_id IS '租户标识';
COMMENT ON COLUMN ds_std_hierarchy.if_delete IS '是否删除记录';
COMMENT ON COLUMN ds_std_hierarchy.creator IS '记录创建人';
COMMENT ON COLUMN ds_std_hierarchy.create_tm IS '记录创建时间';
COMMENT ON COLUMN ds_std_hierarchy.modifier IS '记录修改人';
COMMENT ON COLUMN ds_std_hierarchy.modify_tm IS '记录修改时间';
COMMENT ON COLUMN ds_std_hierarchy.cn_abbr IS '中文简称';
COMMENT ON COLUMN ds_std_hierarchy.en_name IS '英文名称';
COMMENT ON COLUMN ds_std_hierarchy.en_abbr IS '英文简称';
COMMENT ON COLUMN ds_std_hierarchy."describe" IS '描述';



-- ds_std_category definition

-- Drop table

-- DROP TABLE ds_std_category;

CREATE TABLE ds_std_category (
	ds_category_id int8 NOT NULL, -- 数据标准类目标识
	ds_hierarchy_id int8 NOT NULL, -- 数据标准体系标识
	category_num varchar(64) NOT NULL, -- 类目编码
	cn_name varchar(500) NOT NULL, -- 中文名称
	en_name varchar(500) NOT NULL, -- 英文名称
	en_abbr varchar(500) NOT NULL, -- 英文简称
	parent_dgov_category_id int8 NOT NULL, -- 上级数据治理类目标识
	"level" int4 NOT NULL, -- 层级
	seq_num int4 NOT NULL, -- 序号
	"describe" varchar(500) NOT NULL, -- 描述
	preorder_dgov_category_id int8 NULL, -- 前序数据治理类目标识
	follow_dgov_category_id int8 NULL, -- 后继数据治理类目标识
	tenant_id int8 NOT NULL, -- 租户标识
	if_delete varchar(1) NOT NULL, -- 是否删除记录
	creator int8 NOT NULL, -- 记录创建人
	create_tm timestamp NOT NULL, -- 记录创建时间
	modifier int8 NOT NULL, -- 记录修改人
	modify_tm timestamp NOT NULL, -- 记录修改时间
	cn_abbr varchar(500) NULL, -- 中文缩写
	biz_sys_id int8 NULL, -- 业务系统标识
	CONSTRAINT ds_std_category_pkey PRIMARY KEY (ds_category_id)
);
COMMENT ON TABLE ds_std_category IS '标准类目';

-- Column comments

COMMENT ON COLUMN ds_std_category.ds_category_id IS '数据标准类目标识';
COMMENT ON COLUMN ds_std_category.ds_hierarchy_id IS '数据标准体系标识';
COMMENT ON COLUMN ds_std_category.category_num IS '类目编码';
COMMENT ON COLUMN ds_std_category.cn_name IS '中文名称';
COMMENT ON COLUMN ds_std_category.en_name IS '英文名称';
COMMENT ON COLUMN ds_std_category.en_abbr IS '英文简称';
COMMENT ON COLUMN ds_std_category.parent_dgov_category_id IS '上级数据治理类目标识';
COMMENT ON COLUMN ds_std_category."level" IS '层级';
COMMENT ON COLUMN ds_std_category.seq_num IS '序号';
COMMENT ON COLUMN ds_std_category."describe" IS '描述';
COMMENT ON COLUMN ds_std_category.preorder_dgov_category_id IS '前序数据治理类目标识';
COMMENT ON COLUMN ds_std_category.follow_dgov_category_id IS '后继数据治理类目标识';
COMMENT ON COLUMN ds_std_category.tenant_id IS '租户标识';
COMMENT ON COLUMN ds_std_category.if_delete IS '是否删除记录';
COMMENT ON COLUMN ds_std_category.creator IS '记录创建人';
COMMENT ON COLUMN ds_std_category.create_tm IS '记录创建时间';
COMMENT ON COLUMN ds_std_category.modifier IS '记录修改人';
COMMENT ON COLUMN ds_std_category.modify_tm IS '记录修改时间';
COMMENT ON COLUMN ds_std_category.cn_abbr IS '中文缩写';
COMMENT ON COLUMN ds_std_category.biz_sys_id IS '业务系统标识';


-- ds_pub_cd_std definition

-- Drop table

-- DROP TABLE ds_pub_cd_std;

CREATE TABLE ds_pub_cd_std (
	pub_cd_std_id int8 NOT NULL, -- 公共代码标准标识
	std_num varchar(500) NOT NULL, -- 标准编号
	cn_name varchar(500) NOT NULL, -- 中文名称
	cn_abbr varchar(500) NOT NULL, -- 中文简称
	en_name varchar(500) NOT NULL, -- 英文名称
	en_abbr varchar(500) NOT NULL, -- 英文简称
	alias varchar(50) NOT NULL, -- 别名
	datatype_cd varchar(30) NOT NULL, -- 数据类型代码
	data_len int8 NOT NULL, -- 数据长度
	data_scale int8 NOT NULL, -- 数据精度
	num_rule varchar(2000) NOT NULL, -- 编码规则
	biz_def varchar(2000) NOT NULL, -- 业务定义
	biz_charge jsonb NULL, -- 业务负责
	tech_charge jsonb NULL, -- 技术负责
	mgmt_charge jsonb NULL, -- 管理负责
	secu_grade_cd varchar(30) NOT NULL, -- 安全等级代码
	important_grade_cd varchar(30) NOT NULL, -- 重要等级代码
	refer_std_name varchar(500) NOT NULL, -- 参考标准名称
	ext_meta_module_json jsonb NOT NULL, -- 扩展元模型JSON
	edit_status_cd varchar(30) NOT NULL, -- 编辑状态代码
	edit_user_id int8 NOT NULL, -- 编辑用户标识
	tenant_id int8 NOT NULL, -- 租户标识
	if_delete varchar(1) NOT NULL, -- 是否删除记录
	creator int8 NOT NULL, -- 记录创建人
	create_tm timestamp NOT NULL, -- 记录创建时间
	modifier int8 NOT NULL, -- 记录修改人
	modify_tm timestamp NOT NULL, -- 记录修改时间
	ext_meta_module_def_id int8 NOT NULL, -- 扩展元模型定义标识
	ds_category_id int8 NOT NULL, -- 数据标准类目标识
	switch_status_cd varchar(30) NULL, -- 启停状态代码
	"describe" text NOT NULL DEFAULT ''::text, -- 描述
	reference_pub_cd_std_id int8 NULL, -- 引用公共代码标准标识
	mgmt_auth jsonb NULL, -- 管理权限
	edit_auth jsonb NULL, -- 编辑权限
	biz_sys_id int8 NULL, -- 业务系统标识
	code_val_type_cd varchar(30) NULL, -- 码值类型代码
	code_table_name varchar(500) NULL, -- 码表名称
	code_val text NULL, -- 码值
	code_val_explain text NULL, -- 码值说明
	remark varchar(2000) NULL, -- 备注
	CONSTRAINT ds_pub_cd_std_pkey PRIMARY KEY (pub_cd_std_id)
);
COMMENT ON TABLE ds_pub_cd_std IS '公共代码标准';

-- Column comments

COMMENT ON COLUMN ds_pub_cd_std.pub_cd_std_id IS '公共代码标准标识';
COMMENT ON COLUMN ds_pub_cd_std.std_num IS '标准编号';
COMMENT ON COLUMN ds_pub_cd_std.cn_name IS '中文名称';
COMMENT ON COLUMN ds_pub_cd_std.cn_abbr IS '中文简称';
COMMENT ON COLUMN ds_pub_cd_std.en_name IS '英文名称';
COMMENT ON COLUMN ds_pub_cd_std.en_abbr IS '英文简称';
COMMENT ON COLUMN ds_pub_cd_std.alias IS '别名';
COMMENT ON COLUMN ds_pub_cd_std.datatype_cd IS '数据类型代码';
COMMENT ON COLUMN ds_pub_cd_std.data_len IS '数据长度';
COMMENT ON COLUMN ds_pub_cd_std.data_scale IS '数据精度';
COMMENT ON COLUMN ds_pub_cd_std.num_rule IS '编码规则';
COMMENT ON COLUMN ds_pub_cd_std.biz_def IS '业务定义';
COMMENT ON COLUMN ds_pub_cd_std.biz_charge IS '业务负责';
COMMENT ON COLUMN ds_pub_cd_std.tech_charge IS '技术负责';
COMMENT ON COLUMN ds_pub_cd_std.mgmt_charge IS '管理负责';
COMMENT ON COLUMN ds_pub_cd_std.secu_grade_cd IS '安全等级代码';
COMMENT ON COLUMN ds_pub_cd_std.important_grade_cd IS '重要等级代码';
COMMENT ON COLUMN ds_pub_cd_std.refer_std_name IS '参考标准名称';
COMMENT ON COLUMN ds_pub_cd_std.ext_meta_module_json IS '扩展元模型JSON';
COMMENT ON COLUMN ds_pub_cd_std.edit_status_cd IS '编辑状态代码';
COMMENT ON COLUMN ds_pub_cd_std.edit_user_id IS '编辑用户标识';
COMMENT ON COLUMN ds_pub_cd_std.tenant_id IS '租户标识';
COMMENT ON COLUMN ds_pub_cd_std.if_delete IS '是否删除记录';
COMMENT ON COLUMN ds_pub_cd_std.creator IS '记录创建人';
COMMENT ON COLUMN ds_pub_cd_std.create_tm IS '记录创建时间';
COMMENT ON COLUMN ds_pub_cd_std.modifier IS '记录修改人';
COMMENT ON COLUMN ds_pub_cd_std.modify_tm IS '记录修改时间';
COMMENT ON COLUMN ds_pub_cd_std.ext_meta_module_def_id IS '扩展元模型定义标识';
COMMENT ON COLUMN ds_pub_cd_std.ds_category_id IS '数据标准类目标识';
COMMENT ON COLUMN ds_pub_cd_std.switch_status_cd IS '启停状态代码';
COMMENT ON COLUMN ds_pub_cd_std."describe" IS '描述';
COMMENT ON COLUMN ds_pub_cd_std.reference_pub_cd_std_id IS '引用公共代码标准标识';
COMMENT ON COLUMN ds_pub_cd_std.mgmt_auth IS '管理权限';
COMMENT ON COLUMN ds_pub_cd_std.edit_auth IS '编辑权限';
COMMENT ON COLUMN ds_pub_cd_std.biz_sys_id IS '业务系统标识';
COMMENT ON COLUMN ds_pub_cd_std.code_val_type_cd IS '码值类型代码';
COMMENT ON COLUMN ds_pub_cd_std.code_table_name IS '码表名称';
COMMENT ON COLUMN ds_pub_cd_std.code_val IS '码值';
COMMENT ON COLUMN ds_pub_cd_std.code_val_explain IS '码值说明';
COMMENT ON COLUMN ds_pub_cd_std.remark IS '备注';



-- ds_pub_cd_detail definition

-- Drop table

-- DROP TABLE ds_pub_cd_detail;

CREATE TABLE ds_pub_cd_detail (
	pub_cd_detail_id int8 NOT NULL, -- 公共代码明细标识
	pub_cd_std_id int8 NOT NULL, -- 公共代码标准标识
	value_num varchar(64) NOT NULL, -- 取值编码
	cn_name varchar(500) NOT NULL, -- 中文名称
	en_name varchar(500) NOT NULL, -- 英文名称
	"describe" varchar(2000) NOT NULL, -- 描述
	parent_pub_cd_detail_id int8 NOT NULL, -- 上级公共代码明细标识
	tenant_id int8 NOT NULL, -- 租户标识
	if_delete varchar(1) NOT NULL, -- 是否删除记录
	creator int8 NOT NULL, -- 记录创建人
	create_tm timestamp NOT NULL, -- 记录创建时间
	modifier int8 NOT NULL, -- 记录修改人
	modify_tm timestamp NOT NULL, -- 记录修改时间
	cn_abbr varchar(500) NOT NULL DEFAULT ''::character varying, -- 中文简称
	en_abbr varchar(500) NOT NULL DEFAULT ''::character varying, -- 英文简称
	CONSTRAINT ds_pub_cd_detail_pkey PRIMARY KEY (pub_cd_detail_id)
);
COMMENT ON TABLE ds_pub_cd_detail IS '公共代码明细';

-- Column comments

COMMENT ON COLUMN ds_pub_cd_detail.pub_cd_detail_id IS '公共代码明细标识';
COMMENT ON COLUMN ds_pub_cd_detail.pub_cd_std_id IS '公共代码标准标识';
COMMENT ON COLUMN ds_pub_cd_detail.value_num IS '取值编码';
COMMENT ON COLUMN ds_pub_cd_detail.cn_name IS '中文名称';
COMMENT ON COLUMN ds_pub_cd_detail.en_name IS '英文名称';
COMMENT ON COLUMN ds_pub_cd_detail."describe" IS '描述';
COMMENT ON COLUMN ds_pub_cd_detail.parent_pub_cd_detail_id IS '上级公共代码明细标识';
COMMENT ON COLUMN ds_pub_cd_detail.tenant_id IS '租户标识';
COMMENT ON COLUMN ds_pub_cd_detail.if_delete IS '是否删除记录';
COMMENT ON COLUMN ds_pub_cd_detail.creator IS '记录创建人';
COMMENT ON COLUMN ds_pub_cd_detail.create_tm IS '记录创建时间';
COMMENT ON COLUMN ds_pub_cd_detail.modifier IS '记录修改人';
COMMENT ON COLUMN ds_pub_cd_detail.modify_tm IS '记录修改时间';
COMMENT ON COLUMN ds_pub_cd_detail.cn_abbr IS '中文简称';
COMMENT ON COLUMN ds_pub_cd_detail.en_abbr IS '英文简称';


CREATE TABLE ds_base_std_item (
	base_std_item_id int8 NOT NULL, -- 基础标准项标识
	cn_name varchar(500) NOT NULL, -- 中文名称
	cn_abbr varchar(500) NOT NULL, -- 中文简称
	en_name varchar(500) NOT NULL, -- 英文名称
	en_abbr varchar(500) NOT NULL, -- 英文简称
	reference_base_std_id int8 NOT NULL, -- 引用基础标准标识
	reference_pub_cd_std_id int8 NOT NULL, -- 引用公共代码标准标识
	data_format varchar(50) NOT NULL, -- 数据格式
	biz_def varchar(2000) NOT NULL, -- 业务定义
	"domain" varchar(2000) NOT NULL, -- 值域
	data_len int8 NOT NULL, -- 数据长度
	ext_meta_module_json jsonb NOT NULL, -- 扩展元模型JSON
	switch_status_cd varchar(30) NOT NULL, -- 启停状态代码
	edit_user_id int8 NOT NULL, -- 编辑用户标识
	tenant_id int8 NOT NULL, -- 租户标识
	if_delete varchar(1) NOT NULL, -- 是否删除记录
	creator int8 NOT NULL, -- 记录创建人
	create_tm timestamp NOT NULL, -- 记录创建时间
	modifier int8 NOT NULL, -- 记录修改人
	modify_tm timestamp NOT NULL, -- 记录修改时间
	ext_meta_module_def_id int8 NOT NULL, -- 扩展元模型定义标识
	std_num varchar(500) NOT NULL, -- 标准编码
	unit varchar(500) NOT NULL, -- 计算单位
	publish_status_cd varchar(30) NOT NULL, -- 发布状态代码
	copy_base_std_id int8 NOT NULL, -- 复制基础标准标识
	alias varchar(50) NOT NULL, -- 别名
	biz_subject_id int8 NOT NULL, -- 业务主题标识
	biz_rule varchar(2000) NOT NULL, -- 业务规则
	origin_according varchar(50) NOT NULL, -- 来源依据
	decide_biz_sys_id int8 NOT NULL, -- 权威业务系统标识
	info_type_cd varchar(30) NOT NULL, -- 信息类型代码
	data_scale int8 NOT NULL, -- 数据精度
	datatype_id int8 NOT NULL, -- 数据类型标识
	edit_status_cd varchar(30) NOT NULL, -- 编辑状态代码
	if_enable_null varchar(1) NOT NULL, -- 是否允许为空
	biz_charge jsonb NULL, -- 业务负责
	tech_charge jsonb NULL, -- 技术负责
	mgmt_charge jsonb NULL, -- 管理负责
	if_continuous_domain varchar(1) NOT NULL, -- 是否连续值域
	important_grade_cd varchar(30) NOT NULL, -- 重要等级代码
	secu_grade_cd varchar(30) NOT NULL, -- 安全等级代码
	ds_category_id int8 NOT NULL, -- 数据标准类目标识
	"describe" text NULL DEFAULT ''::text, -- 描述
	if_exist_domain varchar(1) NULL, -- 是否存在值域
	mgmt_auth jsonb NULL, -- 管理权限
	edit_auth jsonb NULL, -- 编辑权限
	CONSTRAINT ds_base_std_item_pkey PRIMARY KEY (base_std_item_id)
);
COMMENT ON TABLE ds_base_std_item IS '基础标准项';

-- Column comments

COMMENT ON COLUMN ds_base_std_item.base_std_item_id IS '基础标准项标识';
COMMENT ON COLUMN ds_base_std_item.cn_name IS '中文名称';
COMMENT ON COLUMN ds_base_std_item.cn_abbr IS '中文简称';
COMMENT ON COLUMN ds_base_std_item.en_name IS '英文名称';
COMMENT ON COLUMN ds_base_std_item.en_abbr IS '英文简称';
COMMENT ON COLUMN ds_base_std_item.reference_base_std_id IS '引用基础标准标识';
COMMENT ON COLUMN ds_base_std_item.reference_pub_cd_std_id IS '引用公共代码标准标识';
COMMENT ON COLUMN ds_base_std_item.data_format IS '数据格式';
COMMENT ON COLUMN ds_base_std_item.biz_def IS '业务定义';
COMMENT ON COLUMN ds_base_std_item."domain" IS '值域';
COMMENT ON COLUMN ds_base_std_item.data_len IS '数据长度';
COMMENT ON COLUMN ds_base_std_item.ext_meta_module_json IS '扩展元模型JSON';
COMMENT ON COLUMN ds_base_std_item.switch_status_cd IS '启停状态代码';
COMMENT ON COLUMN ds_base_std_item.edit_user_id IS '编辑用户标识';
COMMENT ON COLUMN ds_base_std_item.tenant_id IS '租户标识';
COMMENT ON COLUMN ds_base_std_item.if_delete IS '是否删除记录';
COMMENT ON COLUMN ds_base_std_item.creator IS '记录创建人';
COMMENT ON COLUMN ds_base_std_item.create_tm IS '记录创建时间';
COMMENT ON COLUMN ds_base_std_item.modifier IS '记录修改人';
COMMENT ON COLUMN ds_base_std_item.modify_tm IS '记录修改时间';
COMMENT ON COLUMN ds_base_std_item.ext_meta_module_def_id IS '扩展元模型定义标识';
COMMENT ON COLUMN ds_base_std_item.std_num IS '标准编码';
COMMENT ON COLUMN ds_base_std_item.unit IS '计算单位';
COMMENT ON COLUMN ds_base_std_item.publish_status_cd IS '发布状态代码';
COMMENT ON COLUMN ds_base_std_item.copy_base_std_id IS '复制基础标准标识';
COMMENT ON COLUMN ds_base_std_item.alias IS '别名';
COMMENT ON COLUMN ds_base_std_item.biz_subject_id IS '业务主题标识';
COMMENT ON COLUMN ds_base_std_item.biz_rule IS '业务规则';
COMMENT ON COLUMN ds_base_std_item.origin_according IS '来源依据';
COMMENT ON COLUMN ds_base_std_item.decide_biz_sys_id IS '权威业务系统标识';
COMMENT ON COLUMN ds_base_std_item.info_type_cd IS '信息类型代码';
COMMENT ON COLUMN ds_base_std_item.data_scale IS '数据精度';
COMMENT ON COLUMN ds_base_std_item.datatype_id IS '数据类型标识';
COMMENT ON COLUMN ds_base_std_item.edit_status_cd IS '编辑状态代码';
COMMENT ON COLUMN ds_base_std_item.if_enable_null IS '是否允许为空';
COMMENT ON COLUMN ds_base_std_item.biz_charge IS '业务负责';
COMMENT ON COLUMN ds_base_std_item.tech_charge IS '技术负责';
COMMENT ON COLUMN ds_base_std_item.mgmt_charge IS '管理负责';
COMMENT ON COLUMN ds_base_std_item.if_continuous_domain IS '是否连续值域';
COMMENT ON COLUMN ds_base_std_item.important_grade_cd IS '重要等级代码';
COMMENT ON COLUMN ds_base_std_item.secu_grade_cd IS '安全等级代码';
COMMENT ON COLUMN ds_base_std_item.ds_category_id IS '数据标准类目标识';
COMMENT ON COLUMN ds_base_std_item."describe" IS '描述';
COMMENT ON COLUMN ds_base_std_item.if_exist_domain IS '是否存在值域';
COMMENT ON COLUMN ds_base_std_item.mgmt_auth IS '管理权限';
COMMENT ON COLUMN ds_base_std_item.edit_auth IS '编辑权限';



CREATE TABLE ds_dim_std (
	dim_std_id int8 NOT NULL, -- 维度标准标识
	cn_name varchar(500) NOT NULL, -- 中文名称
	cn_abbr varchar(500) NOT NULL, -- 中文简称
	en_name varchar(500) NOT NULL, -- 英文名称
	en_abbr varchar(500) NOT NULL, -- 英文简称
	dim_num varchar(500) NOT NULL, -- 维度编码
	alias varchar(50) NOT NULL, -- 别名
	dim_level varchar(50) NOT NULL, -- 维度层级
	valid_period date NOT NULL, -- 有效期限
	std_reference_id int8 NOT NULL, -- 标准引用标识
	dim_std_describe text NOT NULL, -- 维度标准描述
	biz_rule varchar(50) NOT NULL, -- 业务规则
	secu_grade_cd varchar(30) NOT NULL, -- 安全等级代码
	important_grade_cd varchar(30) NOT NULL, -- 重要等级代码
	edit_status_cd varchar(30) NOT NULL, -- 编辑状态代码
	ext_meta_module_json jsonb NOT NULL, -- 扩展元模型JSON
	belong_label_def_id int8 NOT NULL, -- 所属标签定义标识
	belong_label_json jsonb NOT NULL, -- 所属标签JSON
	biz_charge jsonb NULL, -- 业务负责
	tech_charge jsonb NULL, -- 技术负责
	mgmt_charge jsonb NULL, -- 管理负责
	edit_user_id int8 NOT NULL, -- 编辑用户标识
	parent_dim_std_id int8 NOT NULL, -- 上级维度标准标识
	ext_meta_module_def_id int8 NOT NULL, -- 扩展元模型定义标识
	ds_category_id int8 NOT NULL, -- 数据标准类目标识
	tenant_id int8 NOT NULL, -- 租户标识
	if_delete varchar(1) NOT NULL, -- 是否删除记录
	creator int8 NOT NULL, -- 记录创建人
	create_tm timestamp NOT NULL, -- 记录创建时间
	modifier int8 NOT NULL, -- 记录修改人
	modify_tm timestamp NOT NULL, -- 记录修改时间
	"describe" varchar(2000) NULL, -- 描述
	switch_status_cd varchar(30) NULL, -- 启停状态代码
	reference_dim_std_id int8 NULL, -- 引用维度标准标识
	mgmt_auth jsonb NULL, -- 管理权限
	edit_auth jsonb NULL, -- 编辑权限
	CONSTRAINT ds_dim_std_pkey PRIMARY KEY (dim_std_id)
);
COMMENT ON TABLE ds_dim_std IS '维度标准';

-- Column comments

COMMENT ON COLUMN ds_dim_std.dim_std_id IS '维度标准标识';
COMMENT ON COLUMN ds_dim_std.cn_name IS '中文名称';
COMMENT ON COLUMN ds_dim_std.cn_abbr IS '中文简称';
COMMENT ON COLUMN ds_dim_std.en_name IS '英文名称';
COMMENT ON COLUMN ds_dim_std.en_abbr IS '英文简称';
COMMENT ON COLUMN ds_dim_std.dim_num IS '维度编码';
COMMENT ON COLUMN ds_dim_std.alias IS '别名';
COMMENT ON COLUMN ds_dim_std.dim_level IS '维度层级';
COMMENT ON COLUMN ds_dim_std.valid_period IS '有效期限';
COMMENT ON COLUMN ds_dim_std.std_reference_id IS '标准引用标识';
COMMENT ON COLUMN ds_dim_std.dim_std_describe IS '维度标准描述';
COMMENT ON COLUMN ds_dim_std.biz_rule IS '业务规则';
COMMENT ON COLUMN ds_dim_std.secu_grade_cd IS '安全等级代码';
COMMENT ON COLUMN ds_dim_std.important_grade_cd IS '重要等级代码';
COMMENT ON COLUMN ds_dim_std.edit_status_cd IS '编辑状态代码';
COMMENT ON COLUMN ds_dim_std.ext_meta_module_json IS '扩展元模型JSON';
COMMENT ON COLUMN ds_dim_std.belong_label_def_id IS '所属标签定义标识';
COMMENT ON COLUMN ds_dim_std.belong_label_json IS '所属标签JSON';
COMMENT ON COLUMN ds_dim_std.biz_charge IS '业务负责';
COMMENT ON COLUMN ds_dim_std.tech_charge IS '技术负责';
COMMENT ON COLUMN ds_dim_std.mgmt_charge IS '管理负责';
COMMENT ON COLUMN ds_dim_std.edit_user_id IS '编辑用户标识';
COMMENT ON COLUMN ds_dim_std.parent_dim_std_id IS '上级维度标准标识';
COMMENT ON COLUMN ds_dim_std.ext_meta_module_def_id IS '扩展元模型定义标识';
COMMENT ON COLUMN ds_dim_std.ds_category_id IS '数据标准类目标识';
COMMENT ON COLUMN ds_dim_std.tenant_id IS '租户标识';
COMMENT ON COLUMN ds_dim_std.if_delete IS '是否删除记录';
COMMENT ON COLUMN ds_dim_std.creator IS '记录创建人';
COMMENT ON COLUMN ds_dim_std.create_tm IS '记录创建时间';
COMMENT ON COLUMN ds_dim_std.modifier IS '记录修改人';
COMMENT ON COLUMN ds_dim_std.modify_tm IS '记录修改时间';
COMMENT ON COLUMN ds_dim_std."describe" IS '描述';
COMMENT ON COLUMN ds_dim_std.switch_status_cd IS '启停状态代码';
COMMENT ON COLUMN ds_dim_std.reference_dim_std_id IS '引用维度标准标识';
COMMENT ON COLUMN ds_dim_std.mgmt_auth IS '管理权限';
COMMENT ON COLUMN ds_dim_std.edit_auth IS '编辑权限';


CREATE TABLE ds_index_std (
	index_std_id int8 NOT NULL, -- 指标标准标识
	index_num varchar(500) NOT NULL, -- 指标编码
	cn_name varchar(500) NOT NULL, -- 中文名称
	cn_abbr varchar(500) NOT NULL, -- 中文简称
	index_type varchar(30) NOT NULL, -- 指标类型
	en_name varchar(500) NOT NULL, -- 英文名称
	en_abbr varchar(500) NOT NULL, -- 英文简称
	alias varchar(50) NOT NULL, -- 别名
	data_format varchar(50) NOT NULL, -- 数据格式
	measure_unit varchar(50) NOT NULL, -- 度量单位
	index_class_cd int8 NOT NULL, -- 指标分类代码
	biz_datatype_cd varchar(30) NOT NULL, -- 业务数据类型代码
	index_def varchar(2000) NOT NULL, -- 指标定义
	index_expression varchar(500) NOT NULL, -- 指标公式
	ext_meta_module_json jsonb NOT NULL, -- 扩展元模型JSON
	belong_label_json jsonb NOT NULL, -- 所属标签JSON
	edit_status_cd varchar(30) NOT NULL, -- 编辑状态代码
	edit_user_id int8 NOT NULL, -- 编辑用户标识
	biz_rule varchar(2000) NOT NULL, -- 业务规则
	tech_charge jsonb NULL, -- 技术负责
	mgmt_charge jsonb NULL, -- 管理负责
	secu_grade_cd varchar(30) NOT NULL, -- 安全等级代码
	important_grade_cd varchar(30) NOT NULL, -- 重要等级代码
	tenant_id int8 NOT NULL, -- 租户标识
	data_origin_sys_id int8 NOT NULL, -- 数据来源系统标识
	origin_table_id int8 NOT NULL, -- 来源表标识
	if_delete varchar(1) NOT NULL, -- 是否删除记录
	data_len int8 NOT NULL, -- 数据长度
	ext_meta_module_def_id int8 NOT NULL, -- 扩展元模型定义标识
	data_scale int8 NOT NULL, -- 数据精度
	belong_label_def_id int8 NOT NULL, -- 所属标签定义标识
	creator int8 NOT NULL, -- 记录创建人
	create_tm timestamp NOT NULL, -- 记录创建时间
	modifier int8 NOT NULL, -- 记录修改人
	modify_tm timestamp NOT NULL, -- 记录修改时间
	valid_period date NOT NULL, -- 有效期限
	assoc_std_id int8 NOT NULL, -- 关联标准标识
	index_origin varchar(50) NOT NULL, -- 指标来源
	show_scale varchar(50) NOT NULL, -- 显示精度
	datatype_cd varchar(30) NOT NULL, -- 数据类型代码
	cal_cycle varchar(50) NOT NULL, -- 计算周期
	adjust_dt date NOT NULL, -- 调整日期
	ds_category_id int8 NOT NULL, -- 数据标准类目标识
	switch_status_cd varchar(30) NULL, -- 启停状态代码
	biz_charge jsonb NULL, -- 业务负责
	"describe" text NOT NULL DEFAULT ''::text, -- 描述
	reference_index_std_id int8 NULL, -- 引用指标标准标识
	mgmt_auth jsonb NULL, -- 管理权限
	edit_auth jsonb NULL, -- 编辑权限
	subject_name varchar(500) NULL, -- 专题名称
	subject_intro varchar(500) NULL, -- 专题简介
	dev_co varchar(500) NULL, -- 开发公司
	subject_duty_person varchar(500) NULL, -- 专题责任人
	contacts varchar(500) NULL, -- 联系人
	contact_way text NULL, -- 联系方式
	expect_renew_frequency varchar(500) NULL, -- 期望更新频率
	CONSTRAINT ds_index_std_pkey PRIMARY KEY (index_std_id)
);
COMMENT ON TABLE ds_index_std IS '指标标准';

-- Column comments

COMMENT ON COLUMN ds_index_std.index_std_id IS '指标标准标识';
COMMENT ON COLUMN ds_index_std.index_num IS '指标编码';
COMMENT ON COLUMN ds_index_std.cn_name IS '中文名称';
COMMENT ON COLUMN ds_index_std.cn_abbr IS '中文简称';
COMMENT ON COLUMN ds_index_std.index_type IS '指标类型';
COMMENT ON COLUMN ds_index_std.en_name IS '英文名称';
COMMENT ON COLUMN ds_index_std.en_abbr IS '英文简称';
COMMENT ON COLUMN ds_index_std.alias IS '别名';
COMMENT ON COLUMN ds_index_std.data_format IS '数据格式';
COMMENT ON COLUMN ds_index_std.measure_unit IS '度量单位';
COMMENT ON COLUMN ds_index_std.index_class_cd IS '指标分类代码';
COMMENT ON COLUMN ds_index_std.biz_datatype_cd IS '业务数据类型代码';
COMMENT ON COLUMN ds_index_std.index_def IS '指标定义';
COMMENT ON COLUMN ds_index_std.index_expression IS '指标公式';
COMMENT ON COLUMN ds_index_std.ext_meta_module_json IS '扩展元模型JSON';
COMMENT ON COLUMN ds_index_std.belong_label_json IS '所属标签JSON';
COMMENT ON COLUMN ds_index_std.edit_status_cd IS '编辑状态代码';
COMMENT ON COLUMN ds_index_std.edit_user_id IS '编辑用户标识';
COMMENT ON COLUMN ds_index_std.biz_rule IS '业务规则';
COMMENT ON COLUMN ds_index_std.tech_charge IS '技术负责';
COMMENT ON COLUMN ds_index_std.mgmt_charge IS '管理负责';
COMMENT ON COLUMN ds_index_std.secu_grade_cd IS '安全等级代码';
COMMENT ON COLUMN ds_index_std.important_grade_cd IS '重要等级代码';
COMMENT ON COLUMN ds_index_std.tenant_id IS '租户标识';
COMMENT ON COLUMN ds_index_std.data_origin_sys_id IS '数据来源系统标识';
COMMENT ON COLUMN ds_index_std.origin_table_id IS '来源表标识';
COMMENT ON COLUMN ds_index_std.if_delete IS '是否删除记录';
COMMENT ON COLUMN ds_index_std.data_len IS '数据长度';
COMMENT ON COLUMN ds_index_std.ext_meta_module_def_id IS '扩展元模型定义标识';
COMMENT ON COLUMN ds_index_std.data_scale IS '数据精度';
COMMENT ON COLUMN ds_index_std.belong_label_def_id IS '所属标签定义标识';
COMMENT ON COLUMN ds_index_std.creator IS '记录创建人';
COMMENT ON COLUMN ds_index_std.create_tm IS '记录创建时间';
COMMENT ON COLUMN ds_index_std.modifier IS '记录修改人';
COMMENT ON COLUMN ds_index_std.modify_tm IS '记录修改时间';
COMMENT ON COLUMN ds_index_std.valid_period IS '有效期限';
COMMENT ON COLUMN ds_index_std.assoc_std_id IS '关联标准标识';
COMMENT ON COLUMN ds_index_std.index_origin IS '指标来源';
COMMENT ON COLUMN ds_index_std.show_scale IS '显示精度';
COMMENT ON COLUMN ds_index_std.datatype_cd IS '数据类型代码';
COMMENT ON COLUMN ds_index_std.cal_cycle IS '计算周期';
COMMENT ON COLUMN ds_index_std.adjust_dt IS '调整日期';
COMMENT ON COLUMN ds_index_std.ds_category_id IS '数据标准类目标识';
COMMENT ON COLUMN ds_index_std.switch_status_cd IS '启停状态代码';
COMMENT ON COLUMN ds_index_std.biz_charge IS '业务负责';
COMMENT ON COLUMN ds_index_std."describe" IS '描述';
COMMENT ON COLUMN ds_index_std.reference_index_std_id IS '引用指标标准标识';
COMMENT ON COLUMN ds_index_std.mgmt_auth IS '管理权限';
COMMENT ON COLUMN ds_index_std.edit_auth IS '编辑权限';
COMMENT ON COLUMN ds_index_std.subject_name IS '专题名称';
COMMENT ON COLUMN ds_index_std.subject_intro IS '专题简介';
COMMENT ON COLUMN ds_index_std.dev_co IS '开发公司';
COMMENT ON COLUMN ds_index_std.subject_duty_person IS '专题责任人';
COMMENT ON COLUMN ds_index_std.contacts IS '联系人';
COMMENT ON COLUMN ds_index_std.contact_way IS '联系方式';
COMMENT ON COLUMN ds_index_std.expect_renew_frequency IS '期望更新频率';