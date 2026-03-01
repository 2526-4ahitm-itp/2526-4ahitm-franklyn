package at.ac.htlleonding.franklynserver.producer;

import jakarta.enterprise.context.RequestScoped;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Inject;

import io.agroal.api.AgroalDataSource;

import java.sql.Connection;
import java.sql.SQLException;

@RequestScoped
public class ConnectionProducer {

    @Inject
    AgroalDataSource dataSource;

    @Produces
    @RequestScoped
    public Connection produceConnection() throws SQLException {
        return dataSource.getConnection();
    }
}