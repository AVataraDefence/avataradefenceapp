/// Every route of the web project (`../avataradefence/src/app/api`), by name, so screens
/// never hard-code URLs. Paths only; [ApiConfig.baseUrl] is prepended by [ApiClient].
///
/// Request / response bodies are documented in the Postman collection at
/// `../avataradefence/postman/Avatara_Defence_API.postman_collection.json`.
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth / system ──────────────────────────────────────────────────────────
  static const signUp = '/api/auth/signup';
  static const signIn = '/api/auth/signin'; // sets the HttpOnly `session` cookie
  static const signOut = '/api/auth/signout';
  static const myPermissions = '/api/auth/permissions';
  static const dbTest = '/api/db-test'; // connectivity check

  // ── Employee (module key: employee). PUT / DELETE use `<base>/<id>` ──────
  static const employeeInformation = '/api/employee/information';
  static const employeeLinkableUsers = '/api/employee/information/linkable-users';
  static const employeeContact = '/api/employee/contact';
  static const employeeEmergencyContacts = '/api/employee/emergency-contacts';
  static const employeeFamily = '/api/employee/family';
  static const employeeEducation = '/api/employee/education';
  static const employeeWorkExperience = '/api/employee/work-experience';
  static const employeeSkills = '/api/employee/skills';
  static const employeeMedical = '/api/employee/medical';
  static const employeeBank = '/api/employee/bank';
  static const employeeDocuments = '/api/employee/documents'; // multipart on POST / PUT

  // ── Master data (masterData) ───────────────────────────────────────────────
  static const departments = '/api/master-data/departments';
  static const designations = '/api/master-data/designations';
  static const roles = '/api/master-data/roles';

  // ── Organization ───────────────────────────────────────────────────────────
  static const teams = '/api/organization/teams';
  static const teamsLinkableEmployees = '/api/organization/teams/linkable-employees';

  // ── Settings ───────────────────────────────────────────────────────────────
  static const settingsUsers = '/api/settings/users';
  static const settingsProfile = '/api/settings/profile';
  static const settingsProfilePhoto = '/api/settings/profile/photo'; // multipart `file`
  static const settingsPermissions = '/api/settings/permissions'; // ?roleId=
  static String settingsUser(int id) => '/api/settings/users/$id';
  static String settingsUserPhoto(int id) => '/api/settings/users/$id/photo';
  static String settingsUserReportsTo(int id) => '/api/settings/users/$id/reports-to';

  // ── Projects (projects) ────────────────────────────────────────────────────
  static const projects = '/api/projects';
  static const projectUsers = '/api/projects/users';
  static String project(int id) => '/api/projects/$id';
  static String projectDocuments(int id) => '/api/projects/$id/documents'; // multipart `files`
  static String projectDocument(int id, int docId) => '/api/projects/$id/documents/$docId';

  // ── Task management (taskManagement) ───────────────────────────────────────
  static const tasks = '/api/tasks'; // ?scope=mine|assigned|all
  static const taskUsers = '/api/tasks/users';
  static const taskProjects = '/api/tasks/projects';
  static const taskTeam = '/api/tasks/team';
  static String task(int id) => '/api/tasks/$id';
  static String taskComments(int id) => '/api/tasks/$id/comments';
  static String taskChecklist(int id) => '/api/tasks/$id/checklist';
  static String taskChecklistItem(int id, int itemId) => '/api/tasks/$id/checklist/$itemId';
  static String taskDocuments(int id) => '/api/tasks/$id/documents'; // multipart `files`
  static String taskDocument(int id, int docId) => '/api/tasks/$id/documents/$docId';

  // ── Devices (push) ─────────────────────────────────────────────────────────
  static const devices = '/api/devices'; // POST {token, platform}; DELETE ?token=

  // ── Notifications ──────────────────────────────────────────────────────────
  static const notifications = '/api/notifications'; // ?limit=
  static const notificationsRead = '/api/notifications/read'; // {id} or {all: true}

  /// `<base>/<id>` for the Employee / Master data / Teams record routes.
  static String byId(String base, int id) => '$base/$id';
}
