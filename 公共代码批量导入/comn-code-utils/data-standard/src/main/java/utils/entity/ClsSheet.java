package utils.entity;

import com.alibaba.excel.annotation.ExcelProperty;
import lombok.Data;

/**
 * @author long
 */
@Data
public class ClsSheet {

    @ExcelProperty("大类")
    private String bigCls;
    @ExcelProperty("中类")
    private String midCls;
    @ExcelProperty("小类")
    private String litCls;

}
