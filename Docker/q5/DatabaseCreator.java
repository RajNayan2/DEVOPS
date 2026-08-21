import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.util.Scanner;

public class DatabaseCreator {

    public static void main(String[] args) {

        Scanner scanner = new Scanner(System.in);

        System.out.print("Enter username: ");
        String username = scanner.nextLine();

        if (!username.matches("[a-zA-Z0-9_]+")) {
            System.out.println("Invalid username.");
            return;
        }

        String url = "jdbc:mysql://q5-mysql:3306/";
        String user = "root";
        String password = "RootPassword123";

        String sql = "CREATE DATABASE `" + username + "`";

        try {
            Connection connection =
                    DriverManager.getConnection(url, user, password);

            Statement statement = connection.createStatement();

            statement.executeUpdate(sql);

            System.out.println(
                "Database created successfully: " + username
            );

            statement.close();
            connection.close();

        } catch (Exception e) {
            System.out.println("Error: " + e.getMessage());
        }

        scanner.close();
    }
}
