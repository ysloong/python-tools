package utils.entity;

import com.alibaba.excel.annotation.ExcelProperty;
import lombok.Data;

/**
 * @author long
 */
@Data
public class VariablesSheet {

    @ExcelProperty("变量名")
    private String varKey;
    @ExcelProperty("变量值")
    private String varVal;
}
