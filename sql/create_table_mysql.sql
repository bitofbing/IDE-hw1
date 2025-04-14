create table if not exists ppt_files
(
    file_id       varchar(36)                         not null
        primary key,
    file_name     varchar(255)                        not null,
    total_pages   int                                 not null,
    upload_time   timestamp default CURRENT_TIMESTAMP not null,
    mongo_file_id varchar(36)                         null comment '对应MongoDB中的文件ID',
    neo4j_id      varchar(36)                         null comment 'Neo4j中对应的节点ID'
);

create index idx_file_name
    on ppt_files (file_name);

create table if not exists ppt_pages
(
    page_id       varchar(36)  not null
        primary key,
    file_id       varchar(36)  not null,
    page_number   int          not null,
    section_title varchar(100) not null,
    slide_title   varchar(100) null,
    keywords      text         null comment '页面关键词JSON数组',
    constraint uk_file_page
        unique (file_id, page_number),
    constraint ppt_pages_ibfk_1
        foreign key (file_id) references ppt_files (file_id)
            on delete cascade
);

create table if not exists entities
(
    entity_id      varchar(36)               not null
        primary key,
    entity_name    varchar(100)              not null,
    entity_type    varchar(200) charset utf8 not null,
    description    text                      null,
    source_section varchar(50)               null,
    page_id        varchar(36)               null,
    neo4j_id       varchar(36)               null comment 'Neo4j中对应的节点ID',
    constraint entities_ibfk_1
        foreign key (page_id) references ppt_pages (page_id)
            on delete set null
);

create index idx_entity_name
    on entities (entity_name);

create index idx_entity_type
    on entities (entity_type);

create index page_id
    on entities (page_id);

create table if not exists entity_page_history
(
    history_id       varchar(36)                         not null
        primary key,
    entity_id        varchar(36)                         not null,
    previous_page_id varchar(36)                         null,
    new_page_id      varchar(36)                         not null,
    change_reason    varchar(200)                        null,
    change_time      timestamp default CURRENT_TIMESTAMP not null,
    constraint entity_page_history_ibfk_1
        foreign key (entity_id) references entities (entity_id)
            on delete cascade,
    constraint entity_page_history_ibfk_2
        foreign key (previous_page_id) references ppt_pages (page_id)
            on delete set null,
    constraint entity_page_history_ibfk_3
        foreign key (new_page_id) references ppt_pages (page_id)
            on delete cascade
);

create index entity_id
    on entity_page_history (entity_id);

create index idx_change_time
    on entity_page_history (change_time);

create index new_page_id
    on entity_page_history (new_page_id);

create index previous_page_id
    on entity_page_history (previous_page_id);

create table if not exists page_versions
(
    version_id       varchar(36)                         not null
        primary key,
    page_id          varchar(36)                         not null,
    previous_content json                                not null,
    changed_by       varchar(50)                         not null,
    change_time      timestamp default CURRENT_TIMESTAMP not null,
    constraint page_versions_ibfk_1
        foreign key (page_id) references ppt_pages (page_id)
            on delete cascade
);

create index idx_change_time
    on page_versions (change_time);

create index page_id
    on page_versions (page_id);

create index idx_section
    on ppt_pages (section_title);

create table if not exists relations
(
    relation_id      varchar(36) not null
        primary key,
    source_entity_id varchar(36) not null,
    target_entity_id varchar(36) not null,
    relation_type    varchar(50) not null,
    description      text        null,
    constraint relations_ibfk_1
        foreign key (source_entity_id) references entities (entity_id)
            on delete cascade,
    constraint relations_ibfk_2
        foreign key (target_entity_id) references entities (entity_id)
            on delete cascade
);

create table if not exists citations
(
    citation_id      varchar(36)               not null
        primary key,
    entity_id        varchar(36)               null,
    relation_id      varchar(36)               null,
    original_text    text                      not null,
    ppt_section      varchar(50)               not null,
    page_id          varchar(36)               null,
    location_on_page varchar(200) charset utf8 null,
    constraint citations_ibfk_1
        foreign key (entity_id) references entities (entity_id)
            on delete cascade,
    constraint citations_ibfk_2
        foreign key (relation_id) references relations (relation_id)
            on delete cascade,
    constraint citations_ibfk_3
        foreign key (page_id) references ppt_pages (page_id)
            on delete set null
);

create index entity_id
    on citations (entity_id);

create index idx_original_text
    on citations (original_text(255));

create index page_id
    on citations (page_id);

create index relation_id
    on citations (relation_id);

create table if not exists page_locations
(
    location_id  varchar(36)               not null
        primary key,
    page_id      varchar(36)               not null,
    entity_id    varchar(36)               null,
    relation_id  varchar(36)               null,
    x1           int                       not null,
    y1           int                       not null,
    x2           int                       not null,
    y2           int                       not null,
    content_type varchar(200) charset utf8 null,
    constraint page_locations_ibfk_1
        foreign key (page_id) references ppt_pages (page_id)
            on delete cascade,
    constraint page_locations_ibfk_2
        foreign key (entity_id) references entities (entity_id)
            on delete cascade,
    constraint page_locations_ibfk_3
        foreign key (relation_id) references relations (relation_id)
            on delete cascade
);

create index entity_id
    on page_locations (entity_id);

create index idx_x1
    on page_locations (x1);

create index idx_x2
    on page_locations (x2);

create index idx_y1
    on page_locations (y1);

create index idx_y2
    on page_locations (y2);

create index page_id
    on page_locations (page_id);

create index relation_id
    on page_locations (relation_id);

create index idx_relation_type
    on relations (relation_type);

create index source_entity_id
    on relations (source_entity_id);

create index target_entity_id
    on relations (target_entity_id);



