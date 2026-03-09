package fun.hykgraph.exception;

public class EmployeeNotFoundException extends BaseException{

    public EmployeeNotFoundException(){}

    public EmployeeNotFoundException(String msg){
        super(msg);
    }
}
