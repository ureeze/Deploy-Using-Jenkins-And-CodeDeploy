package com.example.springbootgradledemo.congif.auth;

import com.example.springbootgradledemo.congif.auth.dto.OAuthAttributes;
import com.example.springbootgradledemo.congif.auth.dto.SessionUser;
import com.example.springbootgradledemo.domain.user.User;
import com.example.springbootgradledemo.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserService;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.user.DefaultOAuth2User;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpSession;
import java.util.Collections;

@RequiredArgsConstructor
@Service
public class CustomOAuth2UserService implements OAuth2UserService<OAuth2UserRequest, OAuth2User> {

    private final UserRepository userRepository;
    private final HttpSession httpSession;

    @Override
    public OAuth2User loadUser(OAuth2UserRequest userRequest) throws OAuth2AuthenticationException {
        OAuth2UserService delegate = new DefaultOAuth2UserService();
        OAuth2User oAuth2User = delegate.loadUser(userRequest);

        // 현재 로그인 진행 중인 서비스를 구분하는 코드
        // 구글 로그인인지 네이버 로그인인지 구분하기 위해 사용
        String registrationId = userRequest.getClientRegistration().getRegistrationId();

        // OAuth2 로그인 진행 시 키가 되는 필드 값
        // 구글의 기본코드 "sub", 네이버-카카오는 기본지원안함
        // 구글, 네이버 동시 지원시 사용
        String userNameAttributeName = userRequest.getClientRegistration().getProviderDetails()
                .getUserInfoEndpoint().getUserNameAttributeName();

        // OAuth2User 의 attributes 담을 DTO 클래스
        OAuthAttributes attributes = OAuthAttributes.of(registrationId, userNameAttributeName, oAuth2User.getAttributes());

        // 사용자 정보를 담당할 도메인 User Entity 클래스 저장/업데이트
        User user = saveOrUpdate(attributes);

        // 세션저장 - SessionUser DTO 클래스 이용
        httpSession.setAttribute("user", new SessionUser(user));

        return new DefaultOAuth2User(
                Collections.singleton(new SimpleGrantedAuthority(user.getRoleKey())),
                attributes.getAttributes(),
                attributes.getNameAttributeKey());
    }


    private User saveOrUpdate(OAuthAttributes attributes) {
        User user = userRepository.findByEmail(attributes.getEmail())
                .map(entity -> entity.update(attributes.getName(), attributes.getPicture()))
                .orElse(attributes.toEntity());

        return userRepository.save(user);
    }
}
