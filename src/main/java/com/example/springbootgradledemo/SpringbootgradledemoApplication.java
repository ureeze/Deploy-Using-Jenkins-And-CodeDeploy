package com.example.springbootgradledemo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@EnableJpaAuditing
@SpringBootApplication
public class SpringbootgradledemoApplication {

	public static void main(String[] args) {
		SpringApplication.run(SpringbootgradledemoApplication.class, args);
	}

}
