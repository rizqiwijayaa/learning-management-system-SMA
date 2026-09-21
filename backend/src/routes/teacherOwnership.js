const { pool } = require('../db');

function quoteIdentifier(identifier) {
  if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(identifier)) {
    throw new Error(`Identifier tidak valid: ${identifier}`);
  }
  return `\`${identifier}\``;
}

async function requiredTablesReady() {
  const required = ['curriculums', 'teacher_profile', 'app_users'];
  for (const table of required) {
    const [rows] = await pool.query('SHOW TABLES LIKE ?', [table]);
    if (!rows.length) return false;
  }
  return true;
}

async function backfillTeacherOwnership({
  tableName,
  subjectColumn,
  classColumn,
}) {
  if (!(await requiredTablesReady())) return;

  const table = quoteIdentifier(tableName);
  const subjectField = subjectColumn ? quoteIdentifier(subjectColumn) : null;
  const classField = classColumn ? quoteIdentifier(classColumn) : null;

  const mappingSelect = [
    `MIN(u.id) AS teacher_id`,
    `MIN(COALESCE(NULLIF(TRIM(tp.nip), ''), NULLIF(TRIM(u.nip), ''), '')) AS teacher_nip`,
    `MIN(TRIM(c.teacher)) AS teacher_name`,
  ];
  const mappingGroup = [];
  const joinClauses = [];

  if (subjectField) {
    mappingSelect.push(`LOWER(TRIM(c.subject)) AS subject_key`);
    mappingGroup.push(`LOWER(TRIM(c.subject))`);
    joinClauses.push(`LOWER(TRIM(target.${subjectField})) = mapping.subject_key`);
  }

  if (classField) {
    mappingSelect.push(`LOWER(TRIM(CONCAT(c.grade, ' ', c.major))) AS class_prefix`);
    mappingGroup.push(`LOWER(TRIM(CONCAT(c.grade, ' ', c.major)))`);
    joinClauses.push(`LOWER(TRIM(target.${classField})) LIKE CONCAT(mapping.class_prefix, '%')`);
  }

  if (!joinClauses.length) return;

  const mappingSql = `
    SELECT
      ${mappingSelect.join(',\n      ')}
    FROM curriculums c
    LEFT JOIN teacher_profile tp
      ON LOWER(TRIM(tp.name)) = LOWER(TRIM(c.teacher))
    LEFT JOIN app_users u
      ON u.id = tp.id AND u.role = 'Guru'
    WHERE TRIM(COALESCE(c.teacher, '')) <> ''
    GROUP BY ${mappingGroup.join(', ')}
  `;

  await pool.query(`
    UPDATE ${table} target
    JOIN (
      ${mappingSql}
    ) mapping
      ON ${joinClauses.join(' AND ')}
    SET
      target.teacher_id = COALESCE(target.teacher_id, mapping.teacher_id),
      target.teacher_nip = CASE
        WHEN TRIM(COALESCE(target.teacher_nip, '')) = '' THEN mapping.teacher_nip
        ELSE target.teacher_nip
      END,
      target.teacher_name = CASE
        WHEN TRIM(COALESCE(target.teacher_name, '')) = '' THEN mapping.teacher_name
        ELSE target.teacher_name
      END
    WHERE
      target.teacher_id IS NULL
      OR TRIM(COALESCE(target.teacher_nip, '')) = ''
      OR TRIM(COALESCE(target.teacher_name, '')) = ''
  `);
}

module.exports = {
  backfillTeacherOwnership,
};
