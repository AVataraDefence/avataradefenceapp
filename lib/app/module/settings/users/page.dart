import 'package:flutter/material.dart';

import '../../../../components/crud/crud_page.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../../../../core/core.dart';
import '../../../../data/directory.dart';

/// `/module/settings/users` (web `settings/users/page.tsx`).
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Settings',
      backHref: '/module',
      menu: settingsMenu,
      heading: 'System Users',
      subtitle: 'Manage system user accounts and roles',
      addLabel: 'User',
      recordName: 'User',
      statusKey: 'isActive',
      softDelete: true,
      deleteTarget: (r) => userFullName(r),
      sections: [
        const CrudSection('User Details', 'Name, contact and sign-in details', [
          CrudField('firstName', 'First Name', required: true, requiredMessage: 'First name is required'),
          CrudField('middleName', 'Middle Name'),
          CrudField('lastName', 'Last Name', required: true, requiredMessage: 'Last name is required'),
          CrudField('email', 'Email Address', type: CrudFieldType.email, required: true, requiredMessage: 'Email is required'),
          CrudField('phoneNo', 'Phone Number', type: CrudFieldType.phone),
          CrudField('username', 'Username', required: true, requiredMessage: 'Username is required'),
          CrudField('roleId', 'Role', type: CrudFieldType.select, hint: 'Select role', required: true, requiredMessage: 'Role is required', options: roleOptions),
          CrudField('password', 'Password', type: CrudFieldType.password, hint: 'Leave blank to keep the current password'),
        ]),
      ],
      columns: [
        CrudColumn('', (ctx, r) => AppAvatar(name: userFullName(r), imageUrl: r['imageUrl'] as String?, colorSeed: (r['userId'] as num?)?.toInt(), size: AppAvatarSize.sm), width: 56),
        CrudColumn.computed('Full Name', userFullName, width: 170, bold: true),
        CrudColumn.text('Email', 'email', width: 230),
        CrudColumn.text('Phone', 'phoneNo', width: 140),
        CrudColumn.pill('Role', 'roleName', width: 130),
        CrudColumn.text('Username', 'username', width: 120),
      ],
      api: const CrudApi('/api/settings/users', idKey: 'userId', refresh: ['users']),
    );
  }
}
