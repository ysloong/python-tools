package utils;

import com.alibaba.excel.EasyExcel;
import lombok.extern.slf4j.Slf4j;
import utils.entity.ClsSheet;
import utils.entity.VariablesSheet;

import java.util.List;

/**
 * @author long
 * 解析excel，生成公共代码的insert语句
 */
@Slf4j
public class ParseExcelForCommonCode {

    public static final String EXCEL_PATH = "C:\\Users\\long\\Desktop\\工具类\\公共代码批量导入\\公共代码数据.xlsx";

    public static void main(String[] args) {

        // 这里 需要指定读用哪个class去读，然后读取第一个sheet 同步读取会自动finish
        List<VariablesSheet> list = EasyExcel.read(EXCEL_PATH).head(VariablesSheet.class).sheet("变量").doReadSync();
        System.out.println(list);

        List<ClsSheet> objectList = EasyExcel.read(EXCEL_PATH).head(ClsSheet.class).sheet("类目").doReadSync();

        System.out.println(objectList);



    }


}
