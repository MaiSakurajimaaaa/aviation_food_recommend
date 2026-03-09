package fun.hykgraph.service;

import fun.hykgraph.dto.EmployeeDTO;
import fun.hykgraph.dto.EmployeeFixPwdDTO;

import fun.hykgraph.dto.EmployeeLoginDTO;
import fun.hykgraph.dto.PageDTO;
import fun.hykgraph.entity.Employee;
import fun.hykgraph.result.PageResult;

public interface EmployeeService {
    Employee getEmployeeById(Integer id);

    Employee login(EmployeeLoginDTO employeeLoginDTO);

    PageResult employeePageList(PageDTO pageDTO);

    void update(EmployeeDTO employeeDTO);

    void delete(Integer id);

    void onOff(Integer id);

    void addEmployee(EmployeeDTO employeeDTO);

    void fixPwd(EmployeeFixPwdDTO employeeFixPwdDTO);
}
