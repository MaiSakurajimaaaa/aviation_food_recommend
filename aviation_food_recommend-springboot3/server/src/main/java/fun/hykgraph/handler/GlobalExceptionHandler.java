package fun.hykgraph.handler;

import fun.hykgraph.constant.MessageConstant;
import fun.hykgraph.exception.BaseException;
import fun.hykgraph.result.Result;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.sql.SQLIntegrityConstraintViolationException;
import java.sql.SQLException;

/**
 * 全局异常处理器，能对项目中抛出的异常进行捕获和处理
 */
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler
    public Result<String> handleBaseException(BaseException ex){
        log.warn("业务异常: {}", ex.getMessage());
        return Result.error(ex.getMessage());
    }

    @ExceptionHandler
    public Result<String> handleSqlIntegrityException(SQLIntegrityConstraintViolationException ex){
        // Duplicate entry 'zhangsan' for key 'employee.idx_username'
        String message = ex.getMessage();
        if (message.contains("Duplicate entry")){
            String[] split = message.split(" ");
            String username = split[2].replace("'", "");
            String msg = username + MessageConstant.ALREADY_EXiST;
            return Result.error(msg);
        }else {
            return Result.error(MessageConstant.UNKNOWN_ERROR);
        }
    }

    @ExceptionHandler
    public Result<String> handleSqlException(SQLException ex){
        log.error("SQL异常", ex);
        return Result.error("数据库执行失败，请稍后重试");
    }

    @ExceptionHandler
    public Result<String> handleException(Exception ex){
        log.error("系统异常", ex);
        return Result.error("系统繁忙，请稍后再试");
    }
}
